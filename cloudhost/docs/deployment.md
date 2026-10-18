# CloudHost Deployment Guide

This guide provides an end-to-end, ordered walkthrough for deploying the CloudHost portal to your AWS account using Terraform.

---

## 1. Prerequisites Checklist

Before beginning, ensure your local workstation has the following CLI tools installed:

1. **AWS CLI v2** (`aws --version`)
2. **Terraform >= 1.5.0** (`terraform --version`)
3. **Git** (`git --version`)
4. An active **AWS Account** with sufficient IAM administrative permissions.

---

## 2. AWS CLI Setup & Identity Verification

Configure your AWS CLI with programmatic access credentials:

```bash
aws configure
```

You will be prompted for:
- **AWS Access Key ID**: `AKIA...`
- **AWS Secret Access Key**: `...`
- **Default region name**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

Verify that your active identity and account match your expectations:

```bash
aws sts get-caller-identity
```

*Expected output:*
```json
{
    "UserId": "AIDASAMPLEUSERID...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/student-cloud-lab"
}
```

---

## 3. Review and Customize Terraform Variables

Navigate into the `terraform/` directory:

```bash
cd cloudhost/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` using any text editor. At minimum, determine your public IP address to configure the administrator SSH ingress rule:

```bash
curl -s https://checkip.amazonaws.com
```

If your IP is `203.0.113.88`, update `terraform.tfvars`:

```hcl
admin_ip = "203.0.113.88/32"
aws_region = "us-east-1"
environment = "lab"
```

> **Security Alert**: Never commit `terraform.tfvars` to Git if it contains real administrator IPs or sensitive overrides.

---

## 4. Terraform Provisioning Sequence

Execute the following commands in exact order:

### Step 4.1: Initialize Provider Plugins
```bash
terraform init
```
*Downloads the AWS provider and Random provider plugins.*

### Step 4.2: Format Manifests
```bash
terraform fmt -recursive
```
*Ensures uniform HCL formatting across all files.*

### Step 4.3: Validate Syntax and References
```bash
terraform validate
```
*Expected output: `Success! The configuration is valid.`*

### Step 4.4: Generate Execution Plan
```bash
terraform plan -out=tfplan
```
*Reviews the proposed creation of 17+ AWS resources (VPC, Subnets, IGW, Security Groups, EC2, RDS, S3, IAM Roles, Secrets Manager).*

### Step 4.5: Apply Infrastructure Changes
```bash
terraform apply tfplan
```

> **Note on Timing**: Creating the Amazon RDS MySQL instance typically takes **5 to 8 minutes**. Amazon EC2 boots up in approximately 1 to 2 minutes.

---

## 5. Capturing Outputs and Accessing the Portal

Upon completion, Terraform will output your resource identifiers:

```bash
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

ec2_instance_id = "i-0a1b2c3d4e5f67890"
ec2_public_ip = "54.210.45.120"
rds_database_name = "cloudhost_db"
rds_endpoint = "cloudhost-mysql-lab.c12345678901.us-east-1.rds.amazonaws.com:3306"
s3_bucket_name = "cloudhost-storage-lab-a1b2c3d4"
secrets_manager_secret_name = "cloudhost-db-credentials-lab"
ssm_session_manager_command = "aws ssm start-session --target i-0a1b2c3d4e5f67890 --region us-east-1"
website_url = "http://54.210.45.120"
```

---

## 6. Verifying EC2 Cloud-Init Bootstrap

After Terraform completes, the EC2 instance runs its bootstrap cloud-init script (`user_data.sh.tftpl`), which installs Nginx, Gunicorn, Python packages, queries Secrets Manager, and initializes the database.

Allow **1 to 2 minutes** after `terraform apply` finishes for the bootstrap script to complete.

You can verify initialization in real time using AWS SSM Session Manager:

```bash
aws ssm start-session --target <ec2-instance-id>
```

Once inside the instance terminal, check the bootstrap log:

```bash
sudo tail -f /var/log/cloudhost-bootstrap.log
```

Confirm that the systemd service is active:

```bash
sudo systemctl status cloudhost.service
sudo systemctl status nginx
```

---

## 7. Running the Automated Health Check Script

From your local machine, run the health check script against your website URL:

```bash
cd ../scripts
./health_check.sh http://<ec2-public-ip>
```

*Expected output:*
```text
==========================================================
 Running CloudHost Diagnostics on: http://54.210.45.120
==========================================================
Checking Home Page (/)... [PASS] (HTTP 200)
Checking General Health (/health)... [PASS] (HTTP 200)
Checking RDS Database Health (/health/db)... [PASS] (HTTP 200)
Checking Amazon S3 Health (/health/s3)... [PASS] (HTTP 200)
Checking System Dashboard (/dashboard)... [PASS] (HTTP 200)
Checking Upload Form (/upload)... [PASS] (HTTP 200)
==========================================================
Diagnostic Results: 6 Passed, 0 Failed
All infrastructure components (EC2, Nginx, Gunicorn, RDS, S3) are operational!
```

---

## 8. Remote State Configuration (Optional Team Workflow)

For collaborative production deployments, store Terraform state remotely in S3 with state locking via DynamoDB.

Create an S3 bucket and DynamoDB table, then add this block to `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "cloudhost/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Then run `terraform init -migrate-state`.

---

## 9. Safe Teardown

To avoid incurring ongoing AWS charges:

```bash
cd ../scripts
./cleanup.sh
```

The script will purge all versioned objects from the S3 bucket and run `terraform destroy -auto-approve`.

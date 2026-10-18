# CloudHost Troubleshooting & Diagnostic Guide

This document catalogs common issues encountered during cloud deployment and outlines fast diagnostic commands and remedies.

---

## Issue 1: Browser Returns `502 Bad Gateway`

### Symptom
Accessing `http://<ec2-public-ip>` returns a standard Nginx 502 Bad Gateway page.

### Root Cause
Nginx is running on port 80, but Gunicorn is not listening on `127.0.0.1:5000` or has crashed during startup.

### Diagnostics
Connect via SSM Session Manager or SSH and inspect the service status:
```bash
sudo systemctl status cloudhost.service
```

View the Gunicorn application and error logs:
```bash
sudo tail -n 50 /var/log/cloudhost/error.log
sudo journalctl -u cloudhost.service -n 50 --no-pager
```

### Common Fixes
1. Check if the Python virtual environment has missing dependencies:
   ```bash
   /opt/cloudhost/venv/bin/python -c "import flask, pymysql, boto3; print('Libraries OK')"
   ```
2. Verify that `/opt/cloudhost/.env` exists and contains valid variables:
   ```bash
   sudo cat /opt/cloudhost/.env
   ```
3. Restart the systemd service:
   ```bash
   sudo systemctl restart cloudhost.service
   ```

---

## Issue 2: `/health/db` Returns 503 or "RDS Disconnected"

### Symptom
The dashboard indicates **RDS Disconnected** or `/health/db` returns `{ "status": "degraded" }`.

### Root Cause
The EC2 server cannot establish a TCP connection to Amazon RDS on port 3306, or authentication failed.

### Diagnostics
1. Test network reachability from the EC2 instance to RDS:
   ```bash
   nc -z -v -w 5 <rds-endpoint-host> 3306
   ```
2. If `nc` hangs or times out:
   - **Check Security Groups**: The RDS security group must have an inbound rule allowing TCP 3306 from the **EC2 Security Group ID** (`sg-xxxx`).
   - **Check Subnet Route Tables**: Both private subnets must be in the same VPC as the public subnet.
3. If `nc` succeeds but MySQL authentication fails:
   - Check if database credentials in `/opt/cloudhost/.env` match AWS Secrets Manager:
     ```bash
     aws secretsmanager get-secret-value --secret-id cloudhost-db-credentials-lab --query SecretString --output text
     ```

---

## Issue 3: S3 Upload Fails with "Storage Service Error" or 403 Forbidden

### Symptom
When submitting a file upload, the application flashes "Storage service error: Unable to store file in Amazon S3".

### Root Cause
The EC2 IAM role lacks permission to perform `s3:PutObject` on the target bucket, or the bucket name is misconfigured.

### Diagnostics
1. Check the configured bucket name:
   ```bash
   grep S3_BUCKET_NAME /opt/cloudhost/.env
   ```
2. Test S3 API access directly using the EC2 instance's IAM role:
   ```bash
   aws s3 ls "s3://$(grep S3_BUCKET_NAME /opt/cloudhost/.env | cut -d '=' -f2)"
   ```
3. If this fails with `AccessDenied`:
   - Inspect the IAM role attached to the EC2 instance:
     ```bash
     curl -s http://169.254.169.254/latest/meta-data/iam/info
     ```
   - Verify in `terraform/iam.tf` that the policy includes `s3:PutObject`, `s3:GetObject`, and `s3:DeleteObject` for `arn:aws:s3:::<bucket-name>/*`.

---

## Issue 4: `terraform destroy` Fails with `BucketNotEmpty`

### Symptom
Running `terraform destroy` stops with an error similar to:
```text
Error: deleting S3 Bucket (cloudhost-storage-lab-xxx): BucketNotEmpty: The bucket you are trying to delete is not empty.
You must delete all versions in the bucket.
```

### Root Cause
Amazon S3 bucket versioning is enabled. When files are deleted via the web application, S3 creates **Delete Markers**, and previous file revisions remain stored as versions. Terraform refuses to delete non-empty buckets.

### Fix
Execute the project cleanup script, which purges all versions and delete markers before calling destroy:
```bash
cd cloudhost/scripts
./cleanup.sh
```

Or manually purge using the AWS CLI:
```bash
BUCKET_NAME="<your-bucket-name>"

# Delete all object versions
aws s3api delete-objects \
    --bucket "$BUCKET_NAME" \
    --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects \
    --bucket "$BUCKET_NAME" \
    --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output=json --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Re-run destroy
terraform destroy -auto-approve
```

---

## Issue 5: Cloud-Init Bootstrap Incomplete

### Symptom
The EC2 instance has started, but port 80 is closed or Nginx is serving the default Ubuntu welcome page.

### Diagnostics
Check the cloud-init bootstrap log:
```bash
sudo cat /var/log/cloudhost-bootstrap.log
```
Or check the system cloud-init log:
```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

If the script encountered a fatal error during package installation or secret retrieval, the error message and line number will be recorded in `/var/log/cloudhost-bootstrap.log`.

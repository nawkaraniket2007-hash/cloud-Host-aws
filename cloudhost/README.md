# CloudHost: AWS Web Hosting and File Storage Portal

[![AWS Architecture](https://img.shields.io/badge/AWS-VPC%20%7C%20EC2%20%7C%20RDS%20%7C%20S3%20%7C%20IAM-orange.svg)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform%201.5%2B-blue.svg)](https://www.terraform.io/)
[![Flask](https://img.shields.io/badge/Backend-Python%20Flask%203.0-green.svg)](https://palletsprojects.com/p/flask/)
[![License](https://img.shields.io/badge/Academic-B.Tech%20CSE%20Cloud%20Lab-purple.svg)]()

A lightweight, production-conscious cloud computing portal developed for **B.Tech CSE Cloud Computing Lab Demonstrations**. 

**Live Deployment URL**: [http://184.195.187.216](http://184.195.187.216)  
**Public DNS URL**: [http://ec2-184-195-187-216.compute-1.amazonaws.com](http://ec2-184-195-187-216.compute-1.amazonaws.com)

CloudHost deploys a multi-tier web application onto **Amazon EC2 (Ubuntu 22.04 LTS)** using **Nginx** and **Gunicorn**, persists metadata in an encrypted **Amazon DynamoDB** NoSQL table, and stores user-uploaded files directly into an **Amazon S3** bucket hardened with Block Public Access, mandatory TLS in transit, and temporary **Presigned URLs**. Ingested documents automatically trigger **AWS Lambda** for cryptographic SHA-256 integrity verification.

All infrastructure is provisioned, secured, and managed through modular **Terraform (Infrastructure as Code)**.

---

## 1. Architecture Diagram

```mermaid
graph TD
    Client["Client Browser<br/>(Student / Evaluator)"]

    subgraph AWSCloud["AWS Custom VPC (10.0.0.0/16)"]
        IGW["Internet Gateway (IGW)"]

        subgraph PublicSubnet["Public Subnet (10.0.1.0/24)"]
            direction TB
            subgraph EC2["EC2 Instance (Ubuntu 22.04 LTS)"]
                Nginx["Hardened Nginx Reverse Proxy<br/>(Security Headers, Port 80)"]
                Gunicorn["Gunicorn WSGI Server<br/>(127.0.0.1:5000)"]
                Flask["Python Flask Application<br/>(app.py)"]
                Nginx -->|Proxy Pass| Gunicorn
                Gunicorn --> Flask
            end
            EC2SG["Security Group: EC2<br/>Inbound: 80 (0.0.0.0/0)<br/>Inbound: 22 (Admin IP only)"]
        end

        subgraph ServerlessTier["AWS Managed & Serverless Tier"]
            S3["Amazon S3 Bucket<br/>(SSE-S3 AES-256, BPA, TLS Enforced)"]
            Lambda["AWS Lambda Function<br/>(SHA-256 Integrity Verification)"]
            DynamoDB["Amazon DynamoDB<br/>(Encrypted NoSQL Metadata Store)"]
            IAMRole["EC2 & Lambda IAM Roles<br/>(Least-Privilege Scoped Policies)"]
        end
    end

    Client -->|HTTP Port 80| IGW
    IGW --> Nginx
    Flask -->|boto3 API (IAM Profile)| S3
    Flask -->|boto3 API (IAM Profile)| DynamoDB
    S3 -.->|s3:ObjectCreated:* Event| Lambda
    Lambda -->|Update Verified SHA-256| DynamoDB
    EC2 -.->|Assumes Role| IAMRole
```

---

## 2. Technology Stack

| Layer | Component | Description |
| :--- | :--- | :--- |
| **Frontend** | HTML5, CSS3, Bootstrap 5, JavaScript | Responsive portal with live health status, drag-and-drop file upload, and metrics dashboard. |
| **Backend** | Python Flask 3.0 | RESTful routes, parameterized SQL queries, AWS SDK integration, and error handling. |
| **WSGI Server** | Gunicorn | Production Python WSGI HTTP server managed as a background systemd service. |
| **Reverse Proxy** | Nginx | High-performance HTTP server handling reverse proxying, client timeouts, and static asset delivery. |
| **Compute** | Amazon EC2 | Ubuntu Server 22.04 LTS (Jammy) configured with encrypted root EBS volume. |
| **Relational DB** | Amazon RDS for MySQL 8.0 | Multi-AZ DB subnet group, isolated inside private subnets, encrypted at rest. |
| **Object Storage**| Amazon S3 | Bucket versioning enabled, SSE-S3 AES-256 encryption, 100% Block Public Access. |
| **Cloud Security**| AWS IAM & Secrets Manager | Instance Profile delegation (no access keys in code); DB passwords generated and rotated in Secrets Manager. |
| **IaC** | Terraform 1.5+ | Declarative infrastructure specification with zero secrets committed. |

---

## 3. Project Directory Structure

```text
cloudhost/
  ├── app/
  │   ├── app.py                   # Complete Flask application backend
  │   ├── requirements.txt         # Python dependencies
  │   ├── templates/               # HTML5 Bootstrap templates
  │   │   ├── base.html            # Base layout with navbar & live health badge
  │   │   ├── index.html           # Home page with AWS architecture overview
  │   │   ├── dashboard.html       # Analytics dashboard & file records table
  │   │   ├── upload.html          # Drag-and-drop upload form with validation
  │   │   └── error.html           # Safe, sanitized error handler page
  │   └── static/
  │       ├── css/style.css        # AWS color palette styling & pulse indicators
  │       └── js/app.js            # Client-side validation & async health checks
  ├── terraform/
  │   ├── versions.tf              # Constrained Terraform and provider versions
  │   ├── providers.tf             # AWS provider & global resource tagging
  │   ├── variables.tf             # Parameterized input variables & validations
  │   ├── networking.tf            # Custom VPC, Public/Private subnets, IGW, routes
  │   ├── security.tf              # Least-privilege EC2 and RDS security groups
  │   ├── ec2.tf                   # Dynamic Ubuntu AMI lookup & EC2 server resource
  │   ├── rds.tf                   # Amazon RDS MySQL instance & Secrets Manager secret
  │   ├── s3.tf                    # S3 bucket, versioning, SSE-S3, BPA, lifecycle
  │   ├── iam.tf                   # IAM role, policies, and instance profile
  │   ├── outputs.tf               # Public website URL, S3 bucket, RDS endpoint
  │   ├── terraform.tfvars.example # Example variable values for deployment
  │   └── user_data.sh.tftpl       # Cloud-init bootstrap script for automated setup
  ├── scripts/
  │   ├── setup_ec2.sh             # Standalone EC2 manual configuration script
  │   ├── deploy_app.sh            # Hot-reload application code deployment script
  │   ├── health_check.sh          # Automated health diagnostic verification script
  │   └── cleanup.sh               # Safe teardown script (empties S3 & runs destroy)
  ├── docs/
  │   ├── architecture.md          # Architectural deep dive and lab mapping
  │   ├── deployment.md            # Step-by-step deployment guide
  │   └── troubleshooting.md       # Diagnostic scenarios and fast fixes
  ├── .gitignore                   # Comprehensive ignores for state, keys, and venv
  └── README.md                    # Master guide and quickstart
```

---

## 4. Step-by-Step Quickstart (Copy-Paste Commands)

### Step 1: Configure AWS CLI & Verify Identity
```bash
aws configure
aws sts get-caller-identity
```

### Step 2: Configure Terraform Variables
```bash
cd cloudhost/terraform
cp terraform.tfvars.example terraform.tfvars

# Set your current public workstation IP for safe SSH ingress
MY_IP=$(curl -s https://checkip.amazonaws.com)
sed -i "s|127.0.0.1/32|${MY_IP}/32|g" terraform.tfvars
```

### Step 3: Initialize, Plan, and Deploy Infrastructure
```bash
# Initialize provider plugins
terraform init

# Validate formatting and syntax
terraform fmt -recursive
terraform validate

# Review execution plan
terraform plan -out=tfplan

# Provision all cloud resources (takes ~5-7 minutes for RDS)
terraform apply tfplan
```

### Step 4: Access the Website
Once Terraform finishes, view your outputs:
```bash
terraform output website_url
```
Open the generated URL (`http://<ec2-public-ip>`) in your web browser.

### Step 5: Run Automated Health Verification
```bash
cd ../scripts
./health_check.sh
```

---

## 5. Lab Demonstration & Testing Checklist

Use this checklist during your **B.Tech CSE Cloud Computing Lab** evaluation:

- [x] **Website Accessibility**: Load the home page on `http://<ec2-public-ip>`. Observe the system status badges.
- [x] **Health Check Endpoints**:
  - Visit `/health` -> returns HTTP 200 with server hostname.
  - Visit `/health/db` -> verifies internal TCP connection to RDS without leaking credentials.
  - Visit `/health/s3` -> verifies bucket access via EC2 IAM role.
- [x] **File Upload**: Navigate to `/upload`, drag and drop a test file (e.g. `.txt`, `.pdf`, `.png`), and click Upload.
- [x] **Database Metadata Persistence**: Open the `/dashboard` page. Verify that the file name, size, MIME type, and timestamp are listed in the database records table.
- [x] **Presigned URL Downloads**: Click the **Presigned URL** button next to any file. Confirm that your browser downloads the file directly from Amazon S3 via a temporary signed link.
- [x] **File Size & Type Validation**: Try uploading a disallowed file extension or an oversized file. Confirm that the application rejects it gracefully.
- [x] **Database Isolation**: Try connecting to the RDS endpoint directly from your local terminal using `mysql -h <rds-endpoint> -u cloudhost_admin -p`. Confirm that the connection times out (demonstrating true private subnet isolation).
- [x] **Zero Hardcoded Keys**: Inspect `app.py` and `user_data.sh.tftpl`. Verify that no AWS access keys exist. EC2 uses its IAM Instance Profile.

---

## 6. AWS Service to Lab Syllabus Mapping

| AWS Service | Academic Concept | Practical Learning Outcome |
| :--- | :--- | :--- |
| **Amazon EC2** | Infrastructure as a Service (IaaS) | Learn virtual machine provisioning, Linux system administration, systemd service management, and Nginx reverse proxy configuration. |
| **Amazon VPC** | Software-Defined Networking | Understand public/private subnet segmentation, CIDR allocation, Internet Gateways, and route table routing rules. |
| **Amazon RDS** | Platform as a Service (PaaS) | Experience managed relational databases, automated patching, DB subnet groups, and network isolation. |
| **Amazon S3** | Cloud Object Storage | Implement scalable object storage, server-side encryption, versioning, and secure time-limited presigned URLs. |
| **AWS IAM** | Cloud Security & Identity | Master temporary role assumption, instance profiles, and least-privilege JSON policy authoring. |
| **AWS Secrets Manager** | Key & Secret Management | Decouple application configuration from sensitive credentials, avoiding credential leakage in code repositories. |
| **Terraform** | Infrastructure as Code (IaC) | Codify cloud environments into reproducible, declarative configuration files with state tracking. |

---

## 7. Cost Controls & Cleanup

To ensure no unintended AWS charges occur after completing your lab demonstration:

```bash
cd cloudhost/scripts
./cleanup.sh
```

The script will:
1. Delete all object versions and delete markers from your Amazon S3 bucket.
2. Execute `terraform destroy -auto-approve` to terminate the EC2 instance, RDS database, VPC, and IAM roles.
3. Confirm that all billable resources have been purged.

---

## 8. Academic Disclaimer

> **Notice**: This project is structured as an educational demonstration for a university cloud computing laboratory. It is configured for simplicity, cost minimization, and ease of inspection using HTTP. For public production deployments, configure an SSL/TLS certificate via AWS Certificate Manager (ACM) or Let's Encrypt, attach an Application Load Balancer (ALB), mandate user authentication (e.g. Amazon Cognito), and configure AWS WAF.

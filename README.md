# CloudHost: AWS Web Hosting and File Storage Portal

### Live Deployment
- **Website URL**: [http://3.227.13.20](http://3.227.13.20)
- **Public DNS**: [http://ec2-3-227-13-20.compute-1.amazonaws.com](http://ec2-3-227-13-20.compute-1.amazonaws.com)

### Quick Links
- **Application Source**: [`cloudhost/app/`](./cloudhost/app/)
- **Terraform Infrastructure**: [`cloudhost/terraform/`](./cloudhost/terraform/)
- **Automation Scripts**: [`cloudhost/scripts/`](./cloudhost/scripts/)
- **Documentation**:
  - [Architecture Specification](./cloudhost/docs/architecture.md)
  - [Deployment Walkthrough](./cloudhost/docs/deployment.md)
  - [Troubleshooting & Diagnostics](./cloudhost/docs/troubleshooting.md)
- **Full Project Guide**: [CloudHost README](./cloudhost/README.md)

### Quickstart
```bash
cd cloudhost/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

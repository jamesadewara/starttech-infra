# StartTech Infrastructure Provisioning

This repository contains the **Infrastructure as Code (IaC)** codebases, CI/CD orchestration scripts, and CloudWatch alarm definitions for the **StartTech** full-stack deployment.

The infrastructure is entirely provisioned using modular **Terraform** configurations and deployed securely onto **Amazon Web Services (AWS)**.

---

## 📂 Repository Structure

```
starttech-infra/
├── .github/
│   └── workflows/
│       └── infrastructure-deploy.yml # Terraform Plan/Apply Pipeline
├── terraform/                        # Terraform Declarative Provisioners
│   ├── main.tf                       # Main Modules Integrator
│   ├── variables.tf                  # Root Input Variables
│   ├── outputs.tf                    # Root Output Variables
│   ├── modules/
│   │   ├── networking/               # VPC, Subnets, Internet/NAT Gateways
│   │   ├── compute/                  # ASG, ALB, IAM Profiles, Security Groups
│   │   ├── storage/                  # S3 buckets (static web + logs), CloudFront CDN
│   │   └── monitoring/               # CloudWatch Logs, Metrics, ElastiCache Redis
│   └── terraform.tfvars.example      # Sample Environment Variables
├── scripts/
│   └── deploy-infrastructure.sh      # Local Terraform Deployer Bash Script
├── monitoring/                       # System Dashboards & Alerts
│   ├── cloudwatch-dashboard.json     # CW Dashboard Definition
│   ├── alarm-definitions.json        # CW Metric Alarms (CPU, Memory, Disk)
│   └── log-insights-queries.txt      # Log Queries (Slow queries, Error rates)
└── README.md
```

---

## ⚙️ Initial Backend Setup
Before running the Terraform deployment, you must create a secure remote S3 bucket and a DynamoDB table in AWS to store and lock your state files:

> [!NOTE]
> **Database Clarification**: The application itself uses **MongoDB Atlas** (persistent data) and **AWS ElastiCache Redis** (cache tier) exclusively. The DynamoDB table below is **not** an application database; it is strictly used by the **Terraform remote backend** to lock the state file and prevent configuration collisions during parallel deployment runs.

1. **Create the S3 Bucket** (Ensure bucket versioning is enabled):
   ```bash
   aws s3 mb s3://starttech-terraform-state --region us-east-1
   aws s3api put-bucket-versioning --bucket starttech-terraform-state \
     --versioning-configuration Status=Enabled
   ```
2. **Create the DynamoDB Locks Table**:
   Create a DynamoDB table named `starttech-terraform-locks` with a partition key of `LockID` (type String) to prevent state file write collisions.

---

## 🚀 Manual Provisioning Steps

To deploy the infrastructure manually from your local workspace:

1. Navigate to the `terraform` folder:
   ```bash
   cd terraform
   ```
2. Create and fill in your unique TF variables from the template:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your AWS credentials, ECR repository URL, and MongoDB Atlas URI connection string:
   ```hcl
   aws_region         = "us-east-1"
   environment        = "production"
   mongodb_uri        = "mongodb+srv://user:pass@cluster.mongodb.net/much_todo_db"
   redis_password     = "your-strong-auth-token-1234"
   ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/starttech-backend"
   ```
4. Run the local automated deployment helper script:
   ```bash
   ../scripts/deploy-infrastructure.sh
   # Or manually:
   # terraform init
   # terraform plan -out=tfplan
   # terraform apply tfplan
   ```

---

## 🤖 CI/CD Automation Pipeline

Defined in [infrastructure-deploy.yml](file:///c:/Users/pc/Documents/WORKSPACE/PROJECTS/startech/starttech-infra/.github/workflows/infrastructure-deploy.yml).
- **Triggers**: Runs on pushes/merges to the `master` branch or pull requests affecting the `terraform/` subdirectory.
- **Workflow Steps**:
  1. **Checkout & Format**: Performs static code quality and formatting audits (`terraform fmt -check`, `tflint`).
  2. **Security & Validation**: Executes `terraform validate` to verify configuration syntax.
  3. **Plan**: Runs `terraform plan` to display the planned infrastructure additions, changes, and destructions.
  4. **Apply (Master Branch Only)**: Integrates changes directly to production with locking mechanisms.
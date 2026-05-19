#!/bin/bash
# Local automated deployment helper script for StartTech infrastructure.
set -e

# Resolve directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

# Usage information
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -b, --bucket NAME  S3 state bucket name (required for clean runs)"
  echo "  -d, --dry-run      Run terraform plan only (do not apply changes)"
  echo "  -y, --yes          Auto-approve terraform apply (bypass prompt)"
  echo "  -h, --help         Show this help message"
  exit 0
}

DRY_RUN=false
AUTO_APPROVE=""
STATE_BUCKET="${TF_STATE_BUCKET}"

# Parse flags
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -b|--bucket) STATE_BUCKET="$2"; shift 2 ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -y|--yes) AUTO_APPROVE="-auto-approve"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

echo "=== StartTech Infrastructure Deployment ==="
echo "Working directory: $TF_DIR"

cd "$TF_DIR"

# Check for variables file
if [ ! -f "terraform.tfvars" ]; then
  echo "WARNING: terraform.tfvars not found in $TF_DIR"
  if [ -f "terraform.tfvars.example" ]; then
    echo "Copying terraform.tfvars.example to terraform.tfvars..."
    cp terraform.tfvars.example terraform.tfvars
    echo "Please configure your terraform.tfvars with actual parameters before applying!"
    exit 1
  else
    echo "Error: No terraform.tfvars or terraform.tfvars.example found!"
    exit 1
  fi
fi

# Format checks
echo "Checking Terraform formatting..."
terraform fmt -check

# Initialize backend
echo "Initializing Terraform..."
if [ -n "$STATE_BUCKET" ]; then
  echo "Using state bucket: $STATE_BUCKET"
  terraform init -backend-config="bucket=$STATE_BUCKET"
else
  if [ -d ".terraform" ]; then
    echo "Using existing initialized backend..."
    terraform init
  else
    echo "Error: S3 state bucket must be provided using the -b/--bucket flag or the TF_STATE_BUCKET environment variable."
    exit 1
  fi
fi

# Validate syntax
echo "Validating configuration..."
terraform validate

# Plan stage
echo "Creating deployment plan..."
terraform plan -out=tfplan

if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode active. Terraform plan generated successfully. Skipping apply."
  exit 0
fi

# Apply stage
if [ -n "$AUTO_APPROVE" ]; then
  echo "Applying changes (auto-approved)..."
  terraform apply -auto-approve tfplan
else
  echo "Ready to apply changes. Do you want to proceed? (y/N)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Applying changes..."
    terraform apply tfplan
  else
    echo "Apply cancelled by user."
    exit 1
  fi
fi

echo "Infrastructure deployment complete!"

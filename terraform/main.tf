terraform {
  required_version = ">= 1.7.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "starttech-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "starttech-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StartTech"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  environment        = var.environment
}

# Compute Module (EC2, ASG, ALB)
module "compute" {
  source = "./modules/compute"

  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  private_subnet_ids   = module.networking.private_subnet_ids
  public_subnet_ids    = module.networking.public_subnet_ids
  app_port             = var.app_port
  instance_type        = var.instance_type
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  health_check_path    = var.health_check_path
  mongodb_uri          = var.mongodb_uri
  redis_host           = module.monitoring.redis_endpoint
  redis_password       = var.redis_password
  ecr_repository_url   = var.ecr_repository_url
  aws_region           = var.aws_region
}

# Storage Module (S3, CloudFront)
module "storage" {
  source = "./modules/storage"

  environment       = var.environment
  domain_name       = var.domain_name
  certificate_arn   = var.certificate_arn
  alb_dns_name      = module.compute.alb_dns_name
  alb_zone_id       = module.compute.alb_zone_id
}

# Monitoring Module (CloudWatch, ElastiCache)
module "monitoring" {
  source = "./modules/monitoring"

  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  redis_node_type    = var.redis_node_type
  log_retention_days = var.log_retention_days
  asg_name           = module.compute.asg_name
  alb_arn_suffix     = module.compute.alb_arn_suffix
}
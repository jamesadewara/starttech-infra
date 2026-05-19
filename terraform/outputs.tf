output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS (backend API base URL)"
  value       = module.compute.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (frontend URL)"
  value       = module.storage.cloudfront_domain_name
}

output "s3_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = module.storage.bucket_name
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.monitoring.redis_endpoint
  sensitive   = true
}

output "ec2_instance_role_arn" {
  description = "EC2 instance IAM role"
  value       = module.compute.instance_role_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for backend Docker image"
  value       = aws_ecr_repository.backend.repository_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.storage.cloudfront_distribution_id
}
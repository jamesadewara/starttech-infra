output "bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  value = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].domain_name : aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "cloudfront_distribution_id" {
  value = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].id : "disabled"
}
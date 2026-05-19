variable "environment" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "enable_cloudfront" {
  description = "Whether to create CloudFront distribution"
  type        = bool
  default     = false
}
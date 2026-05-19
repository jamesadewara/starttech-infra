variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "app_port" {
  type = number
}

variable "instance_type" {
  type = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "mongodb_uri" {
  type      = string
  sensitive = true
}

variable "redis_host" {
  type = string
}

variable "redis_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "ecr_repository_url" {
  type    = string
  default = ""
}

variable "aws_region" {
  type = string
}

variable "certificate_arn" {
  type    = string
  default = ""
}
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "redis_node_type" { type = string }
variable "log_retention_days" { type = number }
variable "asg_name" { type = string }
variable "alb_arn_suffix" { type = string }
variable "redis_password" { type = string sensitive = true default = "" }
variable "alert_emails" { type = list(string) default = [] }
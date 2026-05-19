output "redis_endpoint" {
  value     = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive = true
}

output "redis_port" {
  value = 6379
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group_backend" {
  value = aws_cloudwatch_log_group.backend.name
}
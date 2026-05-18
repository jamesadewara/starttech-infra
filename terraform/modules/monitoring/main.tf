# ElastiCache Redis
resource "aws_security_group" "redis" {
  name_prefix = "starttech-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_access.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "starttech-${var.environment}-redis-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2_access" {
  name_prefix = "starttech-ec2-redis-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "starttech-${var.environment}-ec2-redis-sg"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "starttech-${var.environment}-redis-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "starttech-${var.environment}-redis"
  description                = "Redis cluster for StartTech"
  node_type                  = var.redis_node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  engine                     = "redis"
  engine_version             = "7.1"
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled   = true
  auth_token                 = var.redis_password != "" ? var.redis_password : null

  snapshot_retention_limit = 5
  snapshot_window        = "03:00-04:00"

  tags = {
    Name = "starttech-${var.environment}-redis"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/starttech/backend"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "starttech-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/starttech/frontend"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "starttech-frontend-logs"
  }
}

resource "aws_cloudwatch_log_group" "user_data" {
  name              = "/starttech/user-data"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "starttech-user-data-logs"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "starttech-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx errors exceeded threshold"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "starttech-${var.environment}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "ALB latency exceeded 2 seconds"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "starttech-${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ASG CPU utilization high"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "starttech-${var.environment}-alerts"

  tags = {
    Name = "starttech-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "StartTech-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ASG CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "ALB Request Count"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '/starttech/backend' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 20"
          region  = "us-east-1"
          title   = "Backend Logs"
          stacked = false
        }
      }
    ]
  })
}
#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script..."

# Update system
dnf update -y

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install CloudWatch Agent
dnf install -y amazon-cloudwatch-agent

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/starttech/app.log",
            "log_group_name": "/starttech/backend",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/starttech/user-data",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "StartTech/Backend",
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create app directories
mkdir -p /var/log/starttech
mkdir -p /opt/starttech

# Login to ECR and pull image
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Run application container
docker run -d \
  --name starttech-backend \
  --restart always \
  -p ${app_port}:${app_port} \
  -e PORT=${app_port} \
  -e MONGODB_URI="${mongodb_uri}" \
  -e REDIS_HOST="${redis_host}" \
  -e REDIS_PASSWORD="${redis_password}" \
  -e ENVIRONMENT=${environment} \
  -e AWS_REGION=${aws_region} \
  -v /var/log/starttech:/app/logs \
  ${ecr_repository_url}:latest

# Health check
sleep 10
curl -f http://localhost:${app_port}${health_check_path} || echo "Health check failed"

echo "User data script completed."
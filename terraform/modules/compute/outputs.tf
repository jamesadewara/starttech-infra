output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "instance_role_arn" {
  value = aws_iam_role.ec2.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2.id
}
# CAS/outputs.tf

output "vpc_id" {
  description = "ID of the VPC being used"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "IDs of the subnets being used"
  value       = var.subnet_ids
}

output "worker_security_group_id" {
  description = "ID of the existing worker security group"
  value       = data.aws_security_group.k8s_worker_sg.id
}

output "worker_launch_template_id" {
  description = "ID of the worker launch template"
  value       = aws_launch_template.k8s_worker_lt.id
}

output "worker_launch_template_latest_version" {
  description = "Latest version of the worker launch template"
  value       = aws_launch_template.k8s_worker_lt.latest_version
}

output "worker_asg_name" {
  description = "Name of the worker auto scaling group"
  value       = aws_autoscaling_group.k8s_worker_asg.name
}

output "worker_asg_arn" {
  description = "ARN of the worker auto scaling group"
  value       = aws_autoscaling_group.k8s_worker_asg.arn
}

output "worker_asg_id" {
  description = "ID of the worker auto scaling group"
  value       = aws_autoscaling_group.k8s_worker_asg.id
}

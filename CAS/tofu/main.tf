# CAS/main.tf
# Infrastructure for Kubernetes Cluster Autoscaler

# Reference existing worker security group
data "aws_security_group" "k8s_worker_sg" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-worker-sg"
  }
}

# Reference existing AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for Worker Nodes
resource "aws_launch_template" "k8s_worker_lt" {
  name_prefix   = "${var.cluster_name}-worker-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  key_name      = var.key_pair_name

  # Attach IAM instance profile
  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_worker_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/cloud-init-worker.yaml", {
    node_name    = "k8s-worker-asg"
    cluster_name = var.cluster_name
  }))

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [data.aws_security_group.k8s_worker_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-worker-node-asg"
      # "kubernetes.io/cluster/${var.cluster_name}" = "owned"  
      # "k8s.io/role/worker"                        = "true"   
      # "kubernetes.io/role/node"                   = "1"      
      # "kubernetes.io/role/elb"                    = "1"     
      "kubernetes.io-cluster-${var.cluster_name}" = "owned"
      "kubernetes.io-role-node"                   = "1"
      "kubernetes.io-role-elb"                    = "1"
      "k8s.io-role-worker"                        = "true"
      "node-type"                                 = "worker"
      "Environment"                               = "production"
      "Managed_by"                                = "Terraform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.cluster_name}-worker-volume-asg"
      "kubernetes.io-cluster-${var.cluster_name}" = "owned"
      "node-type"                                 = "worker"
      "Environment"                               = "production"
      "Managed_by"                                = "Terraform"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tags = {
    Name                                        = "${var.cluster_name}-worker-lt"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "Environment"                               = "production"
    "Managed_by"                                = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Worker Nodes
resource "aws_autoscaling_group" "k8s_worker_asg" {
  name                      = "${var.cluster_name}-worker-asg"
  vpc_zone_identifier       = var.subnet_ids
  desired_capacity          = var.worker_desired_capacity
  max_size                  = var.worker_max_size
  min_size                  = var.worker_min_size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_cooldown          = 300
  termination_policies      = ["OldestInstance"]

  launch_template {
    id      = aws_launch_template.k8s_worker_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/node-pool"
    value               = "default"
    propagate_at_launch = false
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-worker-node-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "node-type"
    value               = "worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }

  tag {
    key                 = "Managed_by"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# CAS/iam.tf
# IAM roles and policies for Kubernetes worker nodes

# IAM Role for Worker Nodes
resource "aws_iam_role" "k8s_worker_role" {
  name = "${var.cluster_name}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name                                        = "${var.cluster_name}-worker-role"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    Environment                                 = "production"
    Managed_by                                  = "Terraform"
  }
}

# IAM Instance Profile for Worker Nodes
resource "aws_iam_instance_profile" "k8s_worker_profile" {
  name = "${var.cluster_name}-worker-profile"
  role = aws_iam_role.k8s_worker_role.name

  tags = {
    Name                                        = "${var.cluster_name}-worker-profile"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    Environment                                 = "production"
    Managed_by                                  = "Terraform"
  }
}

# Policy for Worker Nodes - EC2 Permissions
resource "aws_iam_role_policy" "k8s_worker_policy" {
  name = "${var.cluster_name}-worker-policy"
  role = aws_iam_role.k8s_worker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "worker_ssm_policy" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "worker_ecr_policy" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Optional: CloudWatch Logs policy for container logs
resource "aws_iam_role_policy_attachment" "worker_cloudwatch_policy" {
  role       = aws_iam_role.k8s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Role for Cluster Autoscaler
resource "aws_iam_role" "cluster_autoscaler_role" {
  name = "${var.cluster_name}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name                                        = "${var.cluster_name}-cluster-autoscaler-role"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    Environment                                 = "production"
    Managed_by                                  = "Terraform"
  }
}

# Policy for Cluster Autoscaler
resource "aws_iam_role_policy" "cluster_autoscaler_policy" {
  name = "${var.cluster_name}-cluster-autoscaler-policy"
  role = aws_iam_role.cluster_autoscaler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile for Cluster Autoscaler
resource "aws_iam_instance_profile" "cluster_autoscaler_profile" {
  name = "${var.cluster_name}-cluster-autoscaler-profile"
  role = aws_iam_role.cluster_autoscaler_role.name

  tags = {
    Name                                        = "${var.cluster_name}-cluster-autoscaler-profile"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    Environment                                 = "production"
    Managed_by                                  = "Terraform"
  }
}

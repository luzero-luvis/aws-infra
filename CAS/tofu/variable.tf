# CAS/variables.tf

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-cluster"
}

variable "vpc_id" {
  description = "ID of the existing VPC (from tofu output)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for worker nodes (from tofu output)"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.large"
}

variable "worker_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 0
}

variable "worker_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 0
}

variable "worker_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

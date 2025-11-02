###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "key_pair_name" {
  type        = string
  description = "AWS Key Pair name for SSH access"
  default     = "LuZero"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name"
  default     = "aws-k8s-cluster"
}

variable "management_ips" {
  type        = list(string)
  description = "Management IPs allowed to SSH into cluster nodes"
  default     = ["115.246.211.178/32", "13.127.106.156/32"]
}

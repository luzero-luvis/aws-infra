# Required variables (not in module)
variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "region" {
  description = "AWS region to deploy the cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC (leave empty to create new VPC)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (used when creating new VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "external_source_cidrs" {
  description = "List of CIDR blocks allowed to access the cluster API"
  type        = list(string)
}

# Optional overrides
variable "root_volume_size" {
  description = "Root volume size in GB (note: module uses 50GB by default)"
  type        = number
  default     = 150
}

variable "talos_version" {
  description = "Talos version to use"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave empty for default)"
  type        = string
  default     = ""
}

variable "cluster_architecture" {
  description = "Cluster architecture: amd64 or arm64"
  type        = string
  default     = "amd64"
}

variable "controlplane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 2
}

variable "workers_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "control_plane" {
  description = "Control plane instance configuration"
  type = object({
    instance_type = optional(string)
  })
  default = {}
}

variable "worker_groups" {
  description = "Worker group configurations"
  type = list(object({
    name          = string
    instance_type = optional(string)
  }))
  default = [{ name = "default" }]
}

variable "pod_cidr" {
  description = "CIDR for Kubernetes pods"
  type        = string
  default     = "100.64.0.0/14"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "100.68.0.0/16"
}

variable "disable_kube_proxy" {
  description = "Disable kube-proxy (use Cilium kube-proxy replacement)"
  type        = bool
  default     = true
}

variable "enable_external_cloud_provider" {
  description = "Enable AWS cloud provider"
  type        = bool
  default     = true
}

variable "deploy_external_cloud_provider_iam_policies" {
  description = "Deploy IAM policies for AWS cloud provider"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner for resource tagging"
  type        = string
  default     = ""
}

# Cilium variables
variable "enable_cilium" {
  description = "Enable Cilium CNI installation"
  type        = bool
  default     = true
}

variable "cilium_helm_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.17.4"
}

variable "cilium_helm_values_file_path" {
  description = "Path to Cilium Helm values file"
  type        = string
  default     = "cilium-values.yaml"
}

variable "cilium_helm_values_override_file_path" {
  description = "Path to Cilium Helm values override file"
  type        = string
  default     = ""
}

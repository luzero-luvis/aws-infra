variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "cluster_id" {
  description = "The ID of the cluster (required for Cilium ClusterMesh, 0-255)"
  type        = number
  validation {
    condition     = var.cluster_id >= 0 && var.cluster_id <= 255
    error_message = "Cluster ID must be between 0 and 255"
  }
}

variable "cluster_architecture" {
  description = "Cluster architecture: amd64 or arm64"
  type        = string
  validation {
    condition     = can(regex("^a(rm|md)64$", var.cluster_architecture))
    error_message = "Must be amd64 or arm64"
  }
}

variable "region" {
  description = "AWS region to deploy the cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where to place the VMs"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "external_source_cidrs" {
  description = "List of CIDR blocks allowed to access the cluster API (use /32 for specific IPs)"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "owner" {
  description = "Owner for resource tagging"
  type        = string
}

variable "talos_version" {
  description = "Talos version to use. Check https://github.com/siderolabs/talos/releases"
  type        = string
  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+$", var.talos_version))
    error_message = "Must be a valid Talos version (e.g., v1.11.2)"
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version (defaults to version shipped with Talos). Example: '1.34.1'"
  type        = string
  validation {
    condition     = var.kubernetes_version == "" || can(regex("^\\d+\\.\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "Must be a valid Kubernetes version or empty"
  }
}

variable "controlplane_count" {
  description = "Number of control plane nodes"
  type        = number
  validation {
    condition     = var.controlplane_count >= 1
    error_message = "Must have at least 1 control plane node"
  }
}

variable "workers_count" {
  description = "Number of worker nodes per group"
  type        = number
  validation {
    condition     = var.workers_count >= 0
    error_message = "Workers count cannot be negative"
  }
}

variable "control_plane" {
  description = "Control plane instance configuration"
  type = object({
    instance_type      = optional(string)
    config_patch_files = optional(list(string))
    tags               = optional(map(string))
  })
}

variable "worker_groups" {
  description = "Worker group configurations"
  type = list(object({
    name               = string
    instance_type      = optional(string)
    config_patch_files = optional(list(string))
    tags               = optional(map(string))
  }))
}

variable "pod_cidr" {
  description = "CIDR for Kubernetes pods"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "disable_kube_proxy" {
  description = "Disable kube-proxy (use Cilium kube-proxy replacement)"
  type        = bool
}

variable "disable_containerd_nri_plugins" {
  description = "Disable containerd NRI plugins. See https://www.talos.dev/latest/talos-guides/configuration/containerd/"
  type        = bool
}

variable "allow_workload_on_cp_nodes" {
  description = "Allow workloads on control plane nodes (required for single-node clusters)"
  type        = bool
}

variable "allocate_node_cidrs" {
  description = "Assign pod CIDRs to nodes (required for Cilium 'kubernetes' IPAM mode)"
  type        = bool
}

variable "admission_plugins" {
  description = "Kubernetes admission plugins to enable"
  type        = string
}

variable "config_patch_files" {
  description = "Paths to Talos config patch files applied to all nodes"
  type        = list(string)
}

variable "enable_external_cloud_provider" {
  description = "Enable AWS cloud provider. See https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/"
  type        = bool
}

variable "deploy_external_cloud_provider_iam_policies" {
  description = "Deploy IAM policies for AWS cloud provider"
  type        = bool
  validation {
    condition     = (var.deploy_external_cloud_provider_iam_policies && var.enable_external_cloud_provider) || !var.deploy_external_cloud_provider_iam_policies
    error_message = "Cloud provider must be enabled when deploying IAM policies"
  }
}

variable "external_cloud_provider_manifest" {
  description = "Cloud provider manifest URL (empty string to disable)"
  type        = string
}

variable "iam_instance_profile_control_plane" {
  description = "IAM instance profile for control plane nodes (for AWS CCM)"
  type        = string
}

variable "iam_instance_profile_worker" {
  description = "IAM instance profile for worker nodes (for AWS CCM)"
  type        = string
}

variable "metadata_options" {
  description = "EC2 instance metadata options"
  type        = map(string)
}

variable "enable_cilium" {
  description = "Enable Cilium CNI installation"
  type        = bool
}

variable "cilium_helm_chart" {
  description = "Helm chart name for Cilium"
  type        = string
}

variable "cilium_helm_version" {
  description = "Cilium Helm chart version"
  type        = string
}

variable "cilium_helm_values_file_path" {
  description = "Path to Cilium Helm values file"
  type        = string
}

variable "cilium_helm_values_override_file_path" {
  description = "Path to override Cilium Helm values file"
  type        = string
}

variable "pre_cilium_install_script" {
  description = "Path to pre-install script for Cilium"
  type        = string
}

variable "post_cilium_install_script" {
  description = "Path to post-install script for Cilium"
  type        = string
}

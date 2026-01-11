provider "aws" {
  region = var.region
  default_tags {
    tags = merge(var.tags, var.owner != "" ? { owner = var.owner } : {})
  }
}

provider "talos" {
}

module "talos_cluster" {
  source = "../terraform-aws-talos-module"

  cluster_name    = var.cluster_name
  cluster_id      = 1
  region          = var.region
  vpc_id          = var.vpc_id
  vpc_cidr        = var.vpc_cidr
  tags            = var.tags

  talos_version                  = var.talos_version
  kubernetes_version             = var.kubernetes_version != "" ? var.kubernetes_version : null
  cluster_architecture           = var.cluster_architecture

  controlplane_count             = var.controlplane_count
  workers_count                  = var.workers_count
  control_plane                  = var.control_plane
  worker_groups                  = var.worker_groups

  pod_cidr                       = var.pod_cidr
  service_cidr                   = var.service_cidr

  disable_kube_proxy             = var.disable_kube_proxy
  disable_containerd_nri_plugins = true
  allow_workload_on_cp_nodes     = false
  allocate_node_cidrs            = true

  external_source_cidrs          = var.external_source_cidrs

  enable_external_cloud_provider              = var.enable_external_cloud_provider
  deploy_external_cloud_provider_iam_policies = var.deploy_external_cloud_provider_iam_policies
  external_cloud_provider_manifest            = var.enable_external_cloud_provider ? "https://raw.githubusercontent.com/isovalent/terraform-aws-talos/main/manifests/aws-cloud-controller.yaml" : ""

  root_volume_size                  = var.root_volume_size
}

module "cilium" {
  count = var.enable_cilium ? 1 : 0
  source = "git::https://github.com/isovalent/terraform-k8s-cilium.git?ref=v1.6.7"

  depends_on = [module.talos_cluster]

  cilium_helm_release_name        = "cilium"
  wait_for_total_control_plane_nodes = true
  total_control_plane_nodes       = var.controlplane_count
  cilium_helm_values_file_path    = var.cilium_helm_values_file_path
  cilium_helm_version             = var.cilium_helm_version
  cilium_helm_chart               = "cilium/cilium"
  path_to_kubeconfig_file         = module.talos_cluster.path_to_kubeconfig_file
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = module.talos_cluster.path_to_kubeconfig_file
}

output "talosconfig_path" {
  description = "Path to talosconfig file"
  value       = module.talos_cluster.path_to_talosconfig_file
}

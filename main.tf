provider "aws" {
  region = var.region
  default_tags {
    tags = merge(var.tags, var.owner != "" ? { owner = var.owner } : {})
  }
}

provider "talos" {
}

locals {
  extra_provisioner_environment_variables = {
    CLUSTER_NAME = var.cluster_name
    CLUSTER_ID   = var.cluster_id
    POD_CIDR     = var.pod_cidr
    KUBECONFIG   = module.talos_cluster.path_to_kubeconfig_file
    KUBE_APISERVER_HOST = "localhost"
    KUBE_APISERVER_PORT = "7445"
  }
}

module "talos_cluster" {
  source = "git::https://github.com/isovalent/terraform-aws-talos?ref=v0.9.0"

  cluster_name    = var.cluster_name
  cluster_id      = var.cluster_id
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
  disable_containerd_nri_plugins = var.disable_containerd_nri_plugins
  allow_workload_on_cp_nodes     = var.allow_workload_on_cp_nodes
  allocate_node_cidrs            = var.allocate_node_cidrs

  external_source_cidrs          = var.external_source_cidrs

  admission_plugins              = var.admission_plugins
  config_patch_files             = var.config_patch_files

  enable_external_cloud_provider              = var.enable_external_cloud_provider
  deploy_external_cloud_provider_iam_policies = var.deploy_external_cloud_provider_iam_policies
  external_cloud_provider_manifest            = var.enable_external_cloud_provider ? var.external_cloud_provider_manifest : ""

  iam_instance_profile_control_plane = var.iam_instance_profile_control_plane
  iam_instance_profile_worker        = var.iam_instance_profile_worker
  metadata_options                   = var.metadata_options
}

module "cilium" {
  count = var.enable_cilium ? 1 : 0
  source = "git::https://github.com/isovalent/terraform-k8s-cilium.git?ref=v1.6.7"

  depends_on = [
    module.talos_cluster
  ]

  cilium_helm_release_name              = "cilium"
  wait_for_total_control_plane_nodes    = true
  total_control_plane_nodes             = var.controlplane_count
  cilium_helm_values_file_path          = var.cilium_helm_values_file_path
  cilium_helm_version                   = var.cilium_helm_version
  cilium_helm_chart                     = var.cilium_helm_chart
  path_to_kubeconfig_file               = module.talos_cluster.path_to_kubeconfig_file
  cilium_helm_values_override_file_path = var.cilium_helm_values_override_file_path
  pre_cilium_install_script             = var.pre_cilium_install_script != "" ? file(var.pre_cilium_install_script) : ""
  post_cilium_install_script            = var.post_cilium_install_script != "" ? file(var.post_cilium_install_script) : ""
  extra_provisioner_environment_variables = local.extra_provisioner_environment_variables
}

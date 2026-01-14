output "cluster_name" {
  description = "Name of the Talos cluster"
  value       = module.talos_cluster.cluster_name
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = module.talos_cluster.path_to_kubeconfig_file
}

output "talosconfig_path" {
  description = "Path to the generated talosconfig file"
  value       = module.talos_cluster.path_to_talosconfig_file
}

output "kubeconfig_content" {
  description = "Kubeconfig content (sensitive)"
  value       = module.talos_cluster.kubeconfig
  sensitive   = true
}

output "load_balancer_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = module.talos_cluster.lb_dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Network Load Balancer"
  value       = module.talos_cluster.lb_arn
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Network Load Balancer (for Route53)"
  value       = module.talos_cluster.lb_zone_id
}

output "longhorn_configuration" {
  description = "Longhorn configuration and status"
  value = var.enable_longhorn_prerequisites ? {
    enabled           = true
    system_extensions = [
      "ghcr.io/siderolabs/iscsi-tools:v0.1.6",
      "ghcr.io/siderolabs/util-linux-tools:2.40.2",
      var.enable_nfs_support ? "ghcr.io/siderolabs/nfs-client-tools:v0.1.0" : null,
    ]
    default_path      = "/var/lib/longhorn"
    replica_count     = var.longhorn_replica_count
    storage_class     = var.longhorn_storage_class
    nvme_tcp_enabled  = var.enable_nvme_tcp
    nfs_support       = var.enable_nfs_support
    installation_note = "Cluster deployed! After cluster is ready, run post-install commands to add extensions and install Longhorn. See outputs for commands."
  } : {
    enabled           = false
    system_extensions = []
    default_path      = null
    replica_count     = null
    storage_class     = null
    nvme_tcp_enabled  = false
    nfs_support       = false
    installation_note = "Longhorn prerequisites not enabled. Set enable_longhorn_prerequisites = true to enable."
  }
}

output "availability_zones" {
  description = "Availability zones used for the cluster"
  value       = local.availability_zones
}

output "talos_version" {
  description = "Talos version deployed"
  value       = var.talos_version
}

output "longhorn_post_install_commands" {
  description = "Commands to run after cluster is ready to install Longhorn"
  value = <<-EOT
    # Get node IPs
    export TALOSCONFIG="...talosconfig"
    talosctl get members

    # 1. Apply extraMounts for Longhorn on each node
    talosctl patch machineconfig --nodes <NODE_IP> --patch '{"machine":{"kubelet":{"extraMounts":[{"destination":"/var/lib/longhorn","type":"bind","source":"/var/lib/longhorn","options":["bind","rshared","rw"]}]}}}'

    # 2. Reboot each node
    talosctl reboot --nodes <NODE_IP>

    # 3. After reboot, install Longhorn via Helm
    export KUBECONFIG="...kubeconfig"
    kubectl create namespace longhorn-system
    kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged
    helm install longhorn longhorn/longhorn --namespace longhorn-system --set defaultSettings.defaultDataPath=/var/lib/longhorn
  EOT
}

/* Uncomment if needed
output "control_plane_node_ips" {
  description = "Public IP addresses of control plane nodes"
  value       = module.talos_cluster.control_plane_public_ips
}

output "worker_node_ips" {
  description = "Public IP addresses of worker nodes"
  value       = module.talos_cluster.worker_public_ips
}
*/

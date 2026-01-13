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

/* output "control_plane_node_ips" {
  description = "Public IP addresses of control plane nodes"
  value       = module.talos_cluster.control_plane_public_ips
}

output "worker_node_ips" {
  description = "Public IP addresses of worker nodes"
  value       = module.talos_cluster.worker_public_ips
} */

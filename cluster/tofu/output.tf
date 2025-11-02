output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.k8s_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.k8s_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.k8s_public_subnet[*].id
}

output "master_private_ips" {
  description = "Private IPs of master nodes"
  value       = local.master_private_ips
}

output "master_public_ips" {
  description = "Public IPs of master nodes"
  value       = local.master_public_ips
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = local.worker_private_ips
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = local.worker_public_ips
}

output "master_instance_ids" {
  description = "Instance IDs of master nodes"
  value       = aws_instance.k8s_master_node[*].id
}

output "worker_instance_ids" {
  description = "Instance IDs of worker nodes"
  value       = aws_instance.k8s_worker_node[*].id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "ssh_config_path" {
  description = "Path to the generated SSH config file"
  value       = "../ssh_config"
}

output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = "../ansible/inventory.ini"
}

output "master_connection_info" {
  description = "Master node connection information"
  value = <<-EOT
  
  ═══════════════════════════════════════════════════════════════
  🎯 KUBERNETES MASTER NODE CONNECTION INFO
  ═══════════════════════════════════════════════════════════════
  
  Master Public IP:  ${local.master_public_ips[0]}
  Master Private IP: ${local.master_private_ips[0]}
  
  📝 Direct SSH Access:
  ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${local.master_public_ips[0]}
  
  🔧 Or use SSH config:
  ssh ${var.cluster_name}-master-node-1
  
  ☸️  API Server Access (after cluster init):
  https://${local.master_public_ips[0]}:6443
  
  📦 After getting kubeconfig from master:
  1. Copy from master: 
     scp -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${local.master_public_ips[0]}:/etc/kubernetes/admin.conf ~/.kube/config
  
  2. Update server IP:
     bash ../update-kubeconfig.sh
  
  3. Test connection:
     kubectl cluster-info
     kubectl get nodes
  
  ═══════════════════════════════════════════════════════════════
  EOT
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    Environment                                 = "production"
    Managed_by                                  = "Terraform"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}
resource "aws_subnet" "k8s_public_subnet" {
  count = 3
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.${count.index + 100}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.cluster_name}-public-subnet-${count.index + 1}"
    type                                        = "public"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "aws_route_table" "k8s_public_rt" {
  count = 3
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
  tags = {
    Name = "${var.cluster_name}-public-rt-${count.index + 1}"
  }
}
resource "aws_route_table_association" "k8s_public_rta" {
  count = 3
  subnet_id      = aws_subnet.k8s_public_subnet[count.index].id
  route_table_id = aws_route_table.k8s_public_rt[count.index].id
}
resource "aws_security_group" "k8s_master_sg" {
  name        = "${var.cluster_name}-master-sg"
  description = "Firewall for master instances"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description = "SSH for management_ips"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.management_ips
  }
  ingress {
    description = "API server from management_ips"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.management_ips
  }
  ingress {
    description = "ICMP within VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "API server from workers"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Kubernetes etcd communication"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Allow all TCP traffic within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Allow all UDP traffic within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.cluster_name}-master-sg"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "aws_security_group" "k8s_worker_sg" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Firewall for worker nodes"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description = "Allow SSH connection to servers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.management_ips
  }
  ingress {
    description = "ICMP within VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "HTTP for Istio Gateway"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS for Istio Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow all TCP traffic within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  ingress {
    description = "Allow all UDP traffic within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.cluster_name}-worker-sg"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "aws_instance" "k8s_master_node" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.k8s_public_subnet[0].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.k8s_master_sg.id]
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/cloud-init-master.yaml", {
    node_name = "k8s-master-node-1"
  })
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = {
    Name                                        = "${var.cluster_name}-master-node-1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "k8s.io/role/master"                        = "true"
    "kubernetes.io/role/master"                 = "1"
    "node-type"                                 = "master"
    "Environment"                               = "production"
    "Managed_by"                                = "Terraform"
  }
}
resource "aws_instance" "k8s_worker_node" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.k8s_public_subnet[count.index % length(var.availability_zones)].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.k8s_worker_sg.id]
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/cloud-init-worker.yaml", {
    node_name = "k8s-worker-node-${count.index + 1}"
  })
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  depends_on = [aws_instance.k8s_master_node]
  tags = {
    Name                                        = "${var.cluster_name}-worker-node-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "k8s.io/role/worker"                        = "true"
    "kubernetes.io/role/node"                   = "1"
    "node-type"                                 = "worker"
    "Environment"                               = "production"
    "Managed_by"                                = "Terraform"
  }
}
locals {
  master_private_ips = [
    for instance in aws_instance.k8s_master_node : instance.private_ip
  ]
  master_public_ips = [
    for instance in aws_instance.k8s_master_node : instance.public_ip
  ]
  worker_private_ips = [
    for instance in aws_instance.k8s_worker_node : instance.private_ip
  ]
  worker_public_ips = [
    for instance in aws_instance.k8s_worker_node : instance.public_ip
  ]
}
resource "local_file" "ansible_inventory" {
  content = <<-EOT
[masters]
%{for i, instance in aws_instance.k8s_master_node~}
${instance.tags.Name} ansible_host=${instance.public_ip} private_ipv4=${instance.private_ip} public_ipv4=${instance.public_ip}
%{endfor~}
[workers]
%{for i, instance in aws_instance.k8s_worker_node~}
${instance.tags.Name} ansible_host=${instance.public_ip} private_ipv4=${instance.private_ip} public_ipv4=${instance.public_ip}
%{endfor~}
[all:vars]
ansible_user=ubuntu
ansible_private_key_file=~/.ssh/${var.key_pair_name}.pem
master_ip=${local.master_private_ips[0]}
master_public_ip=${local.master_public_ips[0]}
cluster_name=${var.cluster_name}
vpc_cidr=${aws_vpc.k8s_vpc.cidr_block}
[masters:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
[workers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
  filename = "../ansible/inventory.ini"
}
resource "local_file" "kubeadm_config" {
  content = <<-EOT
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${local.master_private_ips[0]}
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
apiServer:
  advertiseAddress: ${local.master_private_ips[0]}
  bindPort: 6443
  certSANs:
  - ${local.master_private_ips[0]}
  - ${local.master_public_ips[0]}
  - k8s-master-node-1
  - localhost
  - 127.0.0.1
  - kubernetes
  - kubernetes.default
  - kubernetes.default.svc
  - kubernetes.default.svc.cluster.local
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: ${var.cluster_name}
controlPlaneEndpoint: ${local.master_private_ips[0]}:6443
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: v1.33.0
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
proxy: {}
scheduler: {}
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
nodeIP: ${local.master_private_ips[0]}
serverTLSBootstrap: true
EOT
  filename = "../ansible/kubeadm-config.yaml"
}
resource "local_file" "ssh_config" {
  content = <<-EOT
# SSH Config for ${var.cluster_name} cluster
# Master Node (Direct Access via Public IP)
%{for i, instance in aws_instance.k8s_master_node~}
Host ${instance.tags.Name}
  HostName ${instance.public_ip}
  User ubuntu
  IdentityFile ~/.ssh/${var.key_pair_name}.pem
  StrictHostKeyChecking no
%{endfor~}
# Worker Nodes (Direct Access via Public IP)
%{for i, instance in aws_instance.k8s_worker_node~}
Host ${instance.tags.Name}
  HostName ${instance.public_ip}
  User ubuntu
  IdentityFile ~/.ssh/${var.key_pair_name}.pem
  StrictHostKeyChecking no
%{endfor~}
EOT
  filename = "../ssh_config"
}
resource "local_file" "update_kubeconfig_script" {
  content = <<-EOT
#!/bin/bash
# Script to update kubeconfig with public IP after cluster initialization
MASTER_PUBLIC_IP="${local.master_public_ips[0]}"
KUBECONFIG_PATH="$HOME/.kube/config"
echo "Updating kubeconfig with master public IP: $MASTER_PUBLIC_IP"
# Backup original kubeconfig
if [ -f "$KUBECONFIG_PATH" ]; then
  cp "$KUBECONFIG_PATH" "$KUBECONFIG_PATH.backup"
  echo "Backed up existing kubeconfig to $KUBECONFIG_PATH.backup"
fi
# Update server URL in kubeconfig
sed -i.bak "s|server: https://.*:6443|server: https://$MASTER_PUBLIC_IP:6443|g" "$KUBECONFIG_PATH"
echo "Kubeconfig updated successfully!"
echo "Testing connection..."
kubectl cluster-info
EOT
  filename        = "../update-kubeconfig.sh"
  file_permission = "0755"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}


variable "key-name" {
  description = "ssh key name"
  type = string
  default = "vault-key"
}

variable "key-file" {
  description = "actual key file for ssh connection"
  type =  string
  default = "vault-key.pem"
}

variable "my_ip" {
  description = "my ip address for ssh"
  type = string
  default = "0.0.0.0/0"

}

resource "aws_security_group" "vault-security" {
  name        = "vault-security-group"
  description = "Security group for Vault server"

  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "for http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "for http"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    description = "allow all out bound rules"
    from_port = 0
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Vault-SecurityGroup"
    Purpose = "Vault"
  }
}

resource "aws_instance" "vault_server" {
  ami           = "ami-0360c520857e3138f"  # Ubuntu
  instance_type = "t2.medium"              # Recommended for Vault
  key_name      = var.key-name

  vpc_security_group_ids = [aws_security_group.vault-security.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Vault-Server"
    Purpose = "Vault"
    "kubernetes.io/cluster/aws-k8s-cluster" = "owned"
  }
}

resource "local_file" "ansible_inventory" {
  content = <<-EOF
[vault]
${aws_instance.vault_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.key-file}

[vault:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
vault_version=1.15.0
vault_address=0.0.0.0
vault_port=8200

[all:vars]
vault_user=vault
vault_group=vault
vault_config_path=/etc/vault.d
vault_data_path=/opt/vault/data
vault_log_level=info
EOF

  filename = "./ansible/inventory.ini"
  
  depends_on = [aws_instance.vault_server]
}

# Outputs
output "vault_instance_id" {
  description = "ID of the Vault EC2 instance"
  value       = aws_instance.vault_server.id
}

output "vault_public_ip" {
  description = "Public IP address of Vault server"
  value       = aws_instance.vault_server.public_ip
}

output "vault_private_ip" {
  description = "Private IP address of Vault server"
  value       = aws_instance.vault_server.private_ip
}

output "ssh_command" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/${var.key-file} ubuntu@${aws_instance.vault_server.public_ip}"
}

output "vault_url" {
  description = "Vault UI/API URL (via Nginx proxy)"
  value       = "http://${aws_instance.vault_server.public_ip}"
}

output "ansible_command" {
  description = "Command to run Ansible playbook"
  value       = "ansible-playbook -i inventory.ini vault-install.yml"
}

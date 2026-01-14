# AWS Talos Cluster Terraform Configuration

This Terraform configuration deploys a Talos Kubernetes cluster on AWS with:
- **Talos OS v1.12.0** - Linux distribution for Kubernetes
- **Cilium** - eBPF-based CNI and network policy
- **AWS Cloud Controller Manager** - Cloud provider integration
- **Longhorn Ready** - Pre-configured infrastructure for Longhorn

## Prerequisites

- Terraform >= 1.4.0
- AWS credentials configured
- A VPC with public subnets tagged with `type=public`

## Components

### Talos Cluster
Uses [terraform-aws-talos](https://github.com/isovalent/terraform-aws-talos) module to provision EC2 instances and bootstrap Kubernetes.

### AWS Cloud Controller Manager
Enables AWS integration for:
- LoadBalancer services
- Node lifecycle management
- Route53 integration

Enable with: `enable_external_cloud_provider = true`

### Cilium CNI
Uses [terraform-k8s-cilium](https://github.com/isovalent/terraform-k8s-cilium) module for:
- eBPF-based networking
- Network policies
- Hubble observability
- Kube-proxy replacement

### Longhorn Prerequisites
The infrastructure is pre-configured for Longhorn. After deployment, you need to:
1. Add the `/var/lib/longhorn` bind mount to each node
2. Install Longhorn system extensions (iscsi-tools, util-linux-tools)
3. Install Longhorn via Helm

See [longhorn-installation.md](./longhorn-installation.md) for complete steps.

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
tofu init
tofu apply
```

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `cluster_name` | Name of the cluster |
| `region` | AWS region |
| `vpc_id` | VPC ID |
| `external_source_cidrs` | Allowed CIDRs for API access |
| `talos_version` | Talos version (e.g., v1.12.0) |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cluster_id` | `1` | Cluster ID (0-255, for ClusterMesh) |
| `controlplane_count` | `3` | Control plane nodes |
| `workers_count` | `2` | Worker nodes |
| `enable_cilium` | `true` | Install Cilium CNI |
| `enable_external_cloud_provider` | `false` | Install AWS CCM |
| `enable_longhorn_prerequisites` | `true` | Configure for Longhorn |
| `longhorn_default_path` | `/var/lib/longhorn` | Longhorn data path |

### Cilium Configuration

Edit `cilium-values.yaml` to customize:
- Hubble metrics
- IPAM mode (kubernetes/cluster-pool)
- Tunneling vs native routing
- Network policies

## Longhorn Installation

Longhorn is NOT installed by this Terraform configuration. After deployment, follow the steps in [longhorn-installation.md](./longhorn-installation.md).

### Post-Deployment Steps

After `tofu apply` completes:

1. **Get node IPs**:
   ```bash
   export TALOSCONFIG=$(tofu output -raw talosconfig_path)
   talosctl get members
   ```

2. **Apply bind mount to each node**:
   ```bash
   talosctl patch machineconfig --nodes <NODE_IP> \
     --patch '{"machine":{"kubelet":{"extraMounts":[{"destination":"/var/lib/longhorn","type":"bind","source":"/var/lib/longhorn","options":["bind","rshared","rw"]}]}}}'
   ```

3. **Reboot each node**:
   ```bash
   talosctl reboot --nodes <NODE_IP>
   ```

4. **Install Longhorn via Helm**:
   ```bash
   export KUBECONFIG=$(tofu output -raw kubeconfig_path)
   kubectl create namespace longhorn-system
   kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged
   helm install longhorn longhorn/longhorn --namespace longhorn-system
   ```

See [longhorn-installation.md](./longhorn-installation.md) for complete details.

## Outputs

| Output | Description |
|--------|-------------|
| `kubeconfig_path` | Path to kubeconfig file |
| `talosconfig_path` | Path to talosconfig file |
| `load_balancer_dns_name` | NLB DNS name |
| `longhorn_configuration` | Longhorn configuration summary |
| `longhorn_post_install_commands` | Post-install commands for Longhorn |

## Cleanup

```bash
tofu destroy
```

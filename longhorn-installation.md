# Longhorn Installation for Talos v1.12.0

This guide explains how to install Longhorn on a Talos v1.12.0 cluster deployed with this Terraform configuration.

## Overview

Talos v1.12.0 deprecated `machine.install.extensions` in favor of Image Factory schematics. This means system extensions must be installed manually after the cluster is deployed.

## Post-Deployment Steps

After running `tofu apply` and the cluster is ready:

### Step 1: Get Node IPs

```bash
export TALOSCONFIG=$(tofu output -raw talosconfig_path)
talosctl get members
```

### Step 2: Apply Bind Mount to Each Node

For each node (control plane and workers), apply the bind mount configuration:

```bash
# Example for one node - repeat for all nodes
talosctl patch machineconfig --nodes 10.0.0.10 \
  --patch '{"machine":{"kubelet":{"extraMounts":[{"destination":"/var/lib/longhorn","type":"bind","source":"/var/lib/longhorn","options":["bind","rshared","rw"]}]}}}'
```

Repeat for all node IPs.

### Step 3: Reboot Each Node

After patching, reboot each node to apply the changes:

```bash
talosctl reboot --nodes 10.0.0.10
# Repeat for all nodes...
```

Wait for nodes to come back online.

### Step 4: Install Longhorn via Helm

```bash
export KUBECONFIG=$(tofu output -raw kubeconfig_path)

# Create namespace with privileged pod security
kubectl create namespace longhorn-system
kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged

# Add Helm repo and install
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system
```

### Step 5: Verify Installation

```bash
# Check if all pods are running
kubectl get pods -n longhorn-system

# Access Longhorn UI
kubectl get svc -n longhorn-system longhorn-frontend

# Port forward to access UI locally
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

## System Extensions (Optional)

For full Longhorn functionality, the following system extensions are recommended:
- `siderolabs/iscsi-tools` - iSCSI daemon for volume operations
- `siderolabs/util-linux-tools` - fstrim and other utilities

**Note**: In Talos v1.12, system extensions require using Image Factory. For production clusters, consider creating a custom schematic at https://factory.talos.dev.

## Default Configuration

The Helm installation uses these default settings:

| Setting | Value |
|---------|-------|
| defaultDataPath | /var/lib/longhorn |
| defaultReplicaCount | 3 |
| defaultStorageClass | true |
| persistence.defaultClassReplicaCount | 3 |

## Troubleshooting

### Common Issues

1. **Volumes not attaching**: Check pod security policies
2. **iSCSI issues**: Ensure iscsi-tools extension is installed (via Image Factory)
3. **NFS RWX issues**: Ensure NFS client tools are available

### Health Checks

```bash
# Check Longhorn system health
kubectl get health -n longhorn-system

# Check node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}: {.status.conditions[?(@.type=="Longhorn")].status}{"\n"}{end}'

# Check volume status
kubectl get volumes -n longhorn-system
```

## References

- [Longhorn Official Documentation](https://longhorn.io/docs/)
- [Longhorn on Talos Linux](https://longhorn.io/docs/latest/advanced-resources/os-distro-specific/talos-linux-support/)
- [Talos System Extensions](https://www.talos.dev/v1.12/talos-guides/configuration/system-extensions/)
- [Talos Image Factory](https://www.talos.dev/v1.12/platform-specific-installations/boot-assets/)

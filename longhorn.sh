#!/bin/bash

# Create extensions config
cat >worker-extensions.yaml <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
EOF

# Get schematic ID
echo "Getting schematic ID from Talos Factory..."
SCHEMATIC_ID=$(curl -X POST --data-binary @worker-extensions.yaml https://factory.talos.dev/schematics | jq -r .id)
echo "✓ Schematic ID: $SCHEMATIC_ID"
echo ""

# Worker nodes
WORKERS=("10.0.101.106" "10.0.102.32")
WORKER_NAMES=("ip-10-0-101-106.ec2.internal" "ip-10-0-102-32.ec2.internal")

# Upgrade each worker
for i in "${!WORKERS[@]}"; do
  NODE_IP="${WORKERS[$i]}"
  NODE_NAME="${WORKER_NAMES[$i]}"

  echo "================================"
  echo "Upgrading: $NODE_NAME"
  echo "IP: $NODE_IP"
  echo "================================"

  talosctl upgrade \
    --nodes $NODE_IP \
    --image factory.talos.dev/installer/$SCHEMATIC_ID:v1.12.0 \
    --preserve \
    --wait

  echo "Waiting for node to be ready..."
  kubectl wait --for=condition=Ready node/$NODE_NAME --timeout=10m

  echo "Verifying extensions..."
  talosctl --nodes $NODE_IP get extensions

  echo "✓ $NODE_NAME upgraded successfully!"
  echo ""
  sleep 15
done

echo "======================================"
echo "All workers upgraded!"
echo "======================================"

# Final verification
echo ""
echo "Final cluster state:"
kubectl get nodes
echo ""
echo "Extensions on all workers:"
for NODE_IP in "${WORKERS[@]}"; do
  echo "--- $NODE_IP ---"
  talosctl --nodes $NODE_IP get extensions
done

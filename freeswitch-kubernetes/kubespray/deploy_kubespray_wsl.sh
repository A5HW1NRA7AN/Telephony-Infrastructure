#!/bin/bash
set -e

# Resolve directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Find env.sh
if [ -f "$SCRIPT_DIR/env.sh" ]; then
  source "$SCRIPT_DIR/env.sh"
elif [ -f "$TERRAFORM_DIR/env.sh" ]; then
  source "$TERRAFORM_DIR/env.sh"
else
  echo "Error: env.sh not found. Please run 'terraform apply' first in the terraform/ directory." >&2
  exit 1
fi

# Ensure file permissions on private key are correct
chmod 600 "$KEY_PATH"

# Path to Kubespray repository (can be customized by setting KUBESPRAY_DIR)
KUBESPRAY_DIR="${KUBESPRAY_DIR:-/home/rajan/Projects/kubespray}"
KUBESPRAY_ENV="${KUBESPRAY_ENV:-/home/rajan/Projects/kubespray-venv}"

if [ ! -d "$KUBESPRAY_DIR" ]; then
  echo "Error: Kubespray directory not found at $KUBESPRAY_DIR" >&2
  exit 1
fi

echo "==> Deploying Kubespray from WSL..."

# Locate and copy hosts_k8s.yaml
if [ -f "$SCRIPT_DIR/hosts_k8s.yaml" ]; then
  cp -f "$SCRIPT_DIR/hosts_k8s.yaml" "$KUBESPRAY_DIR/inventory/mycluster/hosts.yaml"
elif [ -f "$TERRAFORM_DIR/hosts_k8s.yaml" ]; then
  cp -f "$TERRAFORM_DIR/hosts_k8s.yaml" "$KUBESPRAY_DIR/inventory/mycluster/hosts.yaml"
else
  echo "Error: hosts_k8s.yaml not found. Please run 'terraform apply' first." >&2
  exit 1
fi

# Run playbook
cd "$KUBESPRAY_DIR"
"$KUBESPRAY_ENV/bin/ansible-playbook" -i inventory/mycluster/hosts.yaml --become --become-user=root -u ubuntu --private-key="$KEY_PATH" cluster.yml


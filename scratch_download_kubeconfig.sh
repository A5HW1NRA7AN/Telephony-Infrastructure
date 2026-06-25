#!/bin/bash
# Script to download the remote admin.conf to scratch_kubeconfig and modify it for Proxy server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

TERRAFORM_ENV_DIR="$SCRIPT_DIR/freeswitch-kubernetes/terraform"
if [ -f "$TERRAFORM_ENV_DIR/env.sh" ]; then
  source "$TERRAFORM_ENV_DIR/env.sh"
else
  echo "Error: env.sh not found."
  exit 1
fi

OUTPUT_FILE="$KUBECONFIG_PATH"

echo "==> Fetching remote admin.conf..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP "sudo cat /etc/kubernetes/admin.conf" > "$OUTPUT_FILE"

echo "==> Modifying kubeconfig to point to Proxy IP $PROXY_IP..."
# Replace 127.0.0.1:6443 with Proxy IP
sed -i "s/127.0.0.1:6443/$PROXY_IP:6443/g" "$OUTPUT_FILE"

echo "==> Kubeconfig updated successfully (with secure TLS verification) at $OUTPUT_FILE"

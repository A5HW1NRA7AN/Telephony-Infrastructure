#!/bin/bash
# Script to check the progress of Kubespray installation on the private node
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

echo "=== Kubespray Installation Log (Last 30 lines) ==="
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP "tail -n 30 /home/ubuntu/kubespray_install.log 2>/dev/null || echo 'Log file not yet created.'"

echo ""
echo "=== Screen Session Status ==="
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP "sudo screen -list || echo 'No active screen sessions'"

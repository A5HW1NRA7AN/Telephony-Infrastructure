#!/bin/bash
# Script to fetch kubeconfig from the private server and display it
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

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP "sudo cat /etc/kubernetes/admin.conf"

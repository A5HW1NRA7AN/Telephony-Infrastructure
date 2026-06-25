#!/bin/bash
# Script to configure port forwarding on the Proxy server
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

export PATH="/home/rajan/.local/bin:$PATH"

echo "==> Retrieving Proxy private IP dynamically..."
PROXY_PRIVATE_IP=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=Freeswitch-Kube-proxy" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

if [ -z "$PROXY_PRIVATE_IP" ] || [ "$PROXY_PRIVATE_IP" = "None" ]; then
  echo "Error: Could not retrieve Proxy private IP." >&2
  exit 1
fi

echo "Proxy Private IP: $PROXY_PRIVATE_IP"

echo "==> Configuring port forwarding on Proxy..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" \
  ubuntu@$PROXY_PRIVATE_IP "sudo iptables -t nat -C PREROUTING -p tcp --dport 6443 -j DNAT --to-destination $PRIVATE_IP:6443 2>/dev/null || sudo iptables -t nat -A PREROUTING -p tcp --dport 6443 -j DNAT --to-destination $PRIVATE_IP:6443"

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" \
  ubuntu@$PROXY_PRIVATE_IP "sudo iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null || sudo iptables -t nat -A POSTROUTING -j MASQUERADE"

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" \
  ubuntu@$PROXY_PRIVATE_IP "sudo netfilter-persistent save"

echo "==> Port forwarding configured successfully!"

#!/bin/bash
# Script to run terraform apply on the Kubernetes stack
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

export PATH="/home/rajan/.local/bin:$PATH"
cd "$PROJECT_INFRA_DIR/freeswitch-kubernetes/terraform"

echo "==> Planning before apply..."
terraform plan -input=false -out=tfplan

echo ""
echo "==> Applying plan..."
terraform apply -input=false tfplan

echo ""
echo "==> Terraform apply complete. Outputs:"
terraform output

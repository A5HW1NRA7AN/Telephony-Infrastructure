#!/bin/bash
# Script to run terraform plan on the Kubernetes stack
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

echo "==> Terraform version:"
terraform version

echo ""
echo "==> Running terraform init..."
terraform init -input=false

echo ""
echo "==> Running terraform plan..."
terraform plan -input=false -out=tfplan

echo ""
echo "==> Terraform plan complete. Review above and then apply."

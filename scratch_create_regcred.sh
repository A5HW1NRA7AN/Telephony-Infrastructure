#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"
export PATH="/home/rajan/.local/bin:$PATH"

echo "Checking AWS CLI..."
aws --version

echo "Deleting old regcred..."
kubectl delete secret regcred --ignore-not-found

echo "Getting ECR login password..."
PASSWORD=$(aws ecr get-login-password --region ap-northeast-1)

echo "Creating new regcred secret..."
kubectl create secret docker-registry regcred \
  --docker-server=379220350808.dkr.ecr.ap-northeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$PASSWORD"

echo "Verifying secret..."
kubectl get secret regcred

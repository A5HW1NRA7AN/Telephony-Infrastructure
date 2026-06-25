#!/bin/bash
# Script to programmatically update KUBECONFIG_CONTENT in the local Jenkins .env file
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

KUBECONFIG_FILE="${KUBECONFIG_PATH}"
JENKINS_ENV="${PROJECT_INFRA_DIR}/../Jenkins/.env"

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "Error: scratch_kubeconfig not found."
  exit 1
fi

if [ ! -f "$JENKINS_ENV" ]; then
  echo "Error: Jenkins .env file not found."
  exit 1
fi

echo "==> Encoding kubeconfig to base64..."
K8S_B64=$(base64 -w0 "$KUBECONFIG_FILE")

echo "==> Updating KUBECONFIG_CONTENT in $JENKINS_ENV..."
# Replace the line starting with KUBECONFIG_CONTENT=
# We use a temp file to ensure safe replacement
grep -v "^KUBECONFIG_CONTENT=" "$JENKINS_ENV" > "${JENKINS_ENV}.tmp"
echo "KUBECONFIG_CONTENT=\"$K8S_B64\"" >> "${JENKINS_ENV}.tmp"
mv -f "${JENKINS_ENV}.tmp" "$JENKINS_ENV"

echo "==> Local Jenkins .env updated successfully!"

#!/bin/bash
# Full status check script with error handling and environment variable configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

echo "======== 1. JENKINS STATUS ========"
curl -s -u "$JENKINS_CREDS" "$JENKINS_URL/api/json" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print('Jenkins URL:', d.get('url','?'))
    for j in d.get('jobs',[]):
        print(f'  Job: {j[\"name\"]} - Color: {j[\"color\"]}')
except Exception as e:
    print('Failed to parse Jenkins API:', e)
" 2>/dev/null || echo 'Jenkins unreachable'

echo ""
echo "======== 2. EC2 FREESWITCH CONTAINERS ========"
EC2_ENV_SH="$PROJECT_INFRA_DIR/freeswitch-ec2/terraform/env.sh"
if [ -f "$EC2_ENV_SH" ]; then
  source "$EC2_ENV_SH"
  if [ -n "${BASTION_IP:-}" ]; then
    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
      -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" \
      ubuntu@$PRIVATE_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'" 2>/dev/null || echo 'EC2 private host unreachable'
  else
    echo "BASTION_IP not defined in $EC2_ENV_SH"
  fi
else
  echo "env.sh not found for freeswitch-ec2 at $EC2_ENV_SH"
fi

echo ""
echo "======== 3. K8S PODS ========"
if [ -f "$KUBECONFIG_PATH" ]; then
  kubectl --kubeconfig "$KUBECONFIG_PATH" get pods -A 2>/dev/null || echo 'kubectl connection to cluster failed'
else
  echo "kubeconfig file not found at $KUBECONFIG_PATH"
fi

echo ""
echo "======== 4. GIT STATUS ========"
echo "--- Telephony repo ---"
if [ -d "$PROJECT_APP_DIR" ]; then
  cd "$PROJECT_APP_DIR"
  echo "Branch: $(git branch --show-current)"
  echo "Status: $(git status --porcelain | wc -l) uncommitted changes"
  git log --oneline -3
else
  echo "Telephony directory not found at $PROJECT_APP_DIR"
fi

echo ""
echo "--- Jenkins repo ---"
JENKINS_REPO_DIR="$PROJECT_INFRA_DIR/../Jenkins"
if [ -d "$JENKINS_REPO_DIR" ]; then
  cd "$JENKINS_REPO_DIR"
  echo "Branch: $(git branch --show-current)"
  echo "Status: $(git status --porcelain | wc -l) uncommitted changes"
  git log --oneline -3
else
  echo "Jenkins directory not found at $JENKINS_REPO_DIR"
fi

echo ""
echo "--- Infrastructure repo ---"
if [ -d "$PROJECT_INFRA_DIR" ]; then
  cd "$PROJECT_INFRA_DIR"
  echo "Branch: $(git branch --show-current)"
  echo "Status: $(git status --porcelain | wc -l) uncommitted changes"
  git log --oneline -3
else
  echo "Telephony-Infrastructure directory not found at $PROJECT_INFRA_DIR"
fi

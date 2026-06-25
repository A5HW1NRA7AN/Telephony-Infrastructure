#!/bin/bash
# Script to check git statuses and unpushed commits across all repos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

echo "=== git status for Telephony ==="
if [ -d "$PROJECT_APP_DIR" ]; then
  cd "$PROJECT_APP_DIR"
  git status
  echo "--- Unpushed commits in Telephony ---"
  git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null || echo "No unpushed commits or no remote branch"
else
  echo "Telephony directory not found at $PROJECT_APP_DIR"
fi

echo ""
echo "=== git status for Jenkins ==="
JENKINS_REPO_DIR="$PROJECT_INFRA_DIR/../Jenkins"
if [ -d "$JENKINS_REPO_DIR" ]; then
  cd "$JENKINS_REPO_DIR"
  git status
  echo "--- Unpushed commits in Jenkins ---"
  git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null || echo "No unpushed commits or no remote branch"
else
  echo "Jenkins directory not found at $JENKINS_REPO_DIR"
fi

echo ""
echo "=== git status for Telephony-Infrastructure ==="
if [ -d "$PROJECT_INFRA_DIR" ]; then
  cd "$PROJECT_INFRA_DIR"
  git status
  echo "--- Unpushed commits in Telephony-Infrastructure ---"
  git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null || echo "No unpushed commits or no remote branch"
else
  echo "Telephony-Infrastructure directory not found at $PROJECT_INFRA_DIR"
fi

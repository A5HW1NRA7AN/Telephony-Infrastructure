#!/bin/bash
# Script to trigger the telephony-missed-call pipeline build in Jenkins
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

COOKIE_JAR="/tmp/jenkins_build_cookies.txt"
CREDENTIALS="$JENKINS_CREDS"

echo "==> Fetching crumb..."
CRUMB_JSON=$(curl -s -c "$COOKIE_JAR" -u "$CREDENTIALS" "$JENKINS_URL/crumbIssuer/api/json")

if [[ "$CRUMB_JSON" == *"crumb"* ]]; then
  CRUMB=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumb'])")
  CRUMB_FIELD=$(echo "$CRUMB_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumbRequestField'])")
  echo "Crumb: $CRUMB"
  
  echo "==> Triggering build for telephony-missed-call..."
  curl -s -u "$CREDENTIALS" -b "$COOKIE_JAR" -X POST -H "${CRUMB_FIELD}:${CRUMB}" "$JENKINS_URL/job/telephony-missed-call/build" -o /dev/null -w "HTTP Status: %{http_code}\n"
else
  echo "Failed to retrieve crumb. Response was: $CRUMB_JSON"
fi

#!/bin/bash
# Script to fetch console output of the failed Jenkins build
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

CREDENTIALS="$JENKINS_CREDS"

echo "==> Fetching build log..."
curl -s -u "$CREDENTIALS" "$JENKINS_URL/job/telephony-missed-call/lastBuild/consoleText" | tail -n 100

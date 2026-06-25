#!/bin/bash
# Script to check the last build status of telephony-missed-call job
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

CREDENTIALS="$JENKINS_CREDS"

curl -s -u "$CREDENTIALS" "$JENKINS_URL/job/telephony-missed-call/lastBuild/api/json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(f'Build #{d[\"number\"]}')
    print(f'Building: {d[\"building\"]}')
    print(f'Result: {d[\"result\"]}')
    print(f'Duration: {d[\"duration\"]/1000 if d[\"duration\"] else 0}s')
except Exception as e:
    print('Failed to parse build status:', e)
"

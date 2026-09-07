#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-ap-south-1}"
REQUIRED_TAG="${2:-Environment}"

JSON="$(aws ec2 describe-instances   --region "$REGION"   --query 'Reservations[].Instances[].{ID:InstanceId,Tags:Tags}'   --output json)"

if [[ "$JSON" == "[]" ]]; then
  echo "No EC2 instances found."
  exit 0
fi

python3 - "$REQUIRED_TAG" <<'PY' <<< "$JSON"
import json
import sys

required = sys.argv[1]
items = json.load(sys.stdin)

for item in items:
    tags = {t["Key"]: t.get("Value", "") for t in (item.get("Tags") or [])}
    if required not in tags:
        print(f"MISSING TAG: {item['ID']} -> {required}")
    else:
        print(f"OK: {item['ID']} -> {required}={tags[required]}")
PY

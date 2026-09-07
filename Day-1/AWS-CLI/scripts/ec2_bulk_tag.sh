#!/usr/bin/env bash
set -euo pipefail

REGION="ap-south-1"
TAG="Environment=Dev"
EXECUTE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --execute) EXECUTE=true; shift ;;
    --help)
      echo "Usage: $0 --region REGION --tag KEY=VALUE [--execute]"
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

KEY="${TAG%%=*}"
VALUE="${TAG#*=}"

mapfile -t IDS < <(
  aws ec2 describe-instances     --region "$REGION"     --query 'Reservations[].Instances[].InstanceId'     --output text | tr '\t' '\n'
)

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "No EC2 instances found."
  exit 0
fi

for ID in "${IDS[@]}"; do
  if [[ "$EXECUTE" != true ]]; then
    echo "[DRY-RUN] Would tag $ID with $KEY=$VALUE"
    continue
  fi

  aws ec2 create-tags     --region "$REGION"     --resources "$ID"     --tags "Key=$KEY,Value=$VALUE"

  echo "Tagged $ID"
done

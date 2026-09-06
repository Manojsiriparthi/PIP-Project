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
QUERY="Volumes[?Tags[?Key=='${KEY}' && Value=='${VALUE}']].VolumeId"

mapfile -t VOLUMES < <(
  aws ec2 describe-volumes     --region "$REGION"     --query "$QUERY"     --output text | tr '\t' '\n'
)

if [[ ${#VOLUMES[@]} -eq 0 ]]; then
  echo "No matching EBS volumes."
  exit 0
fi

for VOLUME in "${VOLUMES[@]}"; do
  if [[ "$EXECUTE" != true ]]; then
    echo "[DRY-RUN] Would create snapshot for $VOLUME"
    continue
  fi

  aws ec2 create-snapshot     --region "$REGION"     --volume-id "$VOLUME"     --description "PIP snapshot for $VOLUME"

  echo "Snapshot requested for $VOLUME"
done

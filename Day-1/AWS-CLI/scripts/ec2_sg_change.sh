#!/usr/bin/env bash
set -euo pipefail

REGION="ap-south-1"
GROUP_ID=""
PORT=""
CIDR="10.0.0.0/16"
EXECUTE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --group-id) GROUP_ID="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --cidr) CIDR="$2"; shift 2 ;;
    --execute) EXECUTE=true; shift ;;
    --help)
      echo "Usage: $0 --group-id SG_ID --port PORT [--cidr CIDR] [--execute]"
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$GROUP_ID" || -z "$PORT" ]]; then
  echo "--group-id and --port are required." >&2
  exit 2
fi

if [[ "$EXECUTE" != true ]]; then
  echo "[DRY-RUN] Would allow TCP/$PORT from $CIDR on $GROUP_ID"
  exit 0
fi

aws ec2 authorize-security-group-ingress   --region "$REGION"   --group-id "$GROUP_ID"   --ip-permissions "IpProtocol=tcp,FromPort=$PORT,ToPort=$PORT,IpRanges=[{CidrIp=$CIDR}]"

echo "Security-group rule added."

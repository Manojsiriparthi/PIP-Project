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
QUERY="Reservations[].Instances[?Tags[?Key=='${KEY}' && Value=='${VALUE}']].InstanceId"

mapfile -t IDS < <(
  aws ec2 describe-instances     --region "$REGION"     --query "$QUERY"     --output text | tr '\t' '\n'
)

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "No matching instances."
  exit 0
fi

printf 'Targets:\n'
printf '  %s\n' "${IDS[@]}"

if [[ "$EXECUTE" != true ]]; then
  echo "[DRY-RUN] No instances terminated."
  exit 0
fi

aws ec2 terminate-instances --region "$REGION" --instance-ids "${IDS[@]}"
echo "Termination requested."

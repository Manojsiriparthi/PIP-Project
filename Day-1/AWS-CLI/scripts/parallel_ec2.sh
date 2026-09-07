#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-ap-south-1}"
MAX_PARALLEL="${2:-10}"

mapfile -t IDS < <(
  aws ec2 describe-instances     --region "$REGION"     --query 'Reservations[].Instances[].InstanceId'     --output text | tr '\t' '\n'
)

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "No EC2 instances found."
  exit 0
fi

process_instance() {
  local id="$1"
  aws ec2 describe-instances     --region "$REGION"     --instance-ids "$id"     --query 'Reservations[0].Instances[0].{ID:InstanceId,State:State.Name,Type:InstanceType}'     --output json
}

running=0
for ID in "${IDS[@]}"; do
  process_instance "$ID" &
  ((running+=1))

  if (( running >= MAX_PARALLEL )); then
    wait -n
    ((running-=1))
  fi
done

wait

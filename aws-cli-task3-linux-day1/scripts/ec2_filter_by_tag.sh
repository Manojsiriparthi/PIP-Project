#!/usr/bin/env bash
set -euo pipefail

REGION="ap-south-1"
TAG_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    --tag)
      TAG_FILTER="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--region REGION] [--tag KEY=VALUE]"
      echo
      echo "Examples:"
      echo "  $0"
      echo "  $0 --region ap-south-1"
      echo "  $0 --tag Environment=dev"
      echo "  $0 --tag Project=PIP"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TAG_FILTER" ]]; then

  echo "Showing all EC2 instances and tags in $REGION..."

  aws ec2 describe-instances \
    --region "$REGION" \
    --query 'Reservations[].Instances[].{
      InstanceId:InstanceId,
      Type:InstanceType,
      State:State.Name,
      AZ:Placement.AvailabilityZone,
      PrivateIP:PrivateIpAddress,
      Tags:Tags
    }' \
    --output json

else

  if [[ "$TAG_FILTER" != *=* ]]; then
    echo "ERROR: Tag must be in KEY=VALUE format."
    echo "Example: --tag Environment=dev"
    exit 2
  fi

  TAG_KEY="${TAG_FILTER%%=*}"
  TAG_VALUE="${TAG_FILTER#*=}"

  echo "Filtering EC2 instances by: $TAG_KEY=$TAG_VALUE"

  QUERY="Reservations[].Instances[?Tags[?Key=='${TAG_KEY}' && Value=='${TAG_VALUE}']].{
    InstanceId:InstanceId,
    Type:InstanceType,
    State:State.Name,
    AZ:Placement.AvailabilityZone,
    PrivateIP:PrivateIpAddress,
    Tags:Tags
  }"

  aws ec2 describe-instances \
    --region "$REGION" \
    --query "$QUERY" \
    --output json

fi

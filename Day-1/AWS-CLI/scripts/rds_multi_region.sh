#!/usr/bin/env bash
set -euo pipefail

REGIONS="${1:-ap-south-1 us-east-1}"

for REGION in $REGIONS; do
  echo "=== RDS: $REGION ==="
  if ! aws rds describe-db-instances       --region "$REGION"       --query 'DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,Status:DBInstanceStatus,AZ:AvailabilityZone}'       --output table; then
    echo "WARNING: RDS query failed in $REGION" >&2
  fi
done

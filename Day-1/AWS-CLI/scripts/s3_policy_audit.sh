#!/usr/bin/env bash
set -euo pipefail

mapfile -t BUCKETS < <(
  aws s3api list-buckets     --query 'Buckets[].Name'     --output text | tr '\t' '\n'
)

if [[ ${#BUCKETS[@]} -eq 0 ]]; then
  echo "No S3 buckets found."
  exit 0
fi

for BUCKET in "${BUCKETS[@]}"; do
  echo "=== Bucket: $BUCKET ==="
  if ! aws s3api get-bucket-policy       --bucket "$BUCKET"       --query Policy       --output text; then
    echo "No bucket policy or access denied."
  fi
done

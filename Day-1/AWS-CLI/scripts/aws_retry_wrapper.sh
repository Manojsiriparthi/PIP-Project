#!/usr/bin/env bash
set -u

MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"
BASE_DELAY="${BASE_DELAY:-2}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <aws-subcommand> [arguments...]"
  echo "Example: $0 ec2 describe-instances --region ap-south-1"
  exit 2
fi

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
  echo "Attempt ${attempt}/${MAX_ATTEMPTS}: aws $*"

  if aws "$@"; then
    exit 0
  fi

  if (( attempt == MAX_ATTEMPTS )); then
    echo "AWS command failed after ${MAX_ATTEMPTS} attempts." >&2
    exit 1
  fi

  jitter_ms=$(( RANDOM % 1000 ))
  delay_ms=$(( BASE_DELAY * 2 ** (attempt - 1) * 1000 + jitter_ms ))

  echo "Command failed. Retrying after ${delay_ms} ms..." >&2
  sleep "$(awk "BEGIN {print ${delay_ms}/1000}")"
done

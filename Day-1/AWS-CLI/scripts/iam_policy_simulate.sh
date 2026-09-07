#!/usr/bin/env bash
set -euo pipefail

POLICY_ARN=""
ACTION="ec2:DescribeInstances"
RESOURCE_ARN="*"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --policy-arn) POLICY_ARN="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --resource-arn) RESOURCE_ARN="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 --policy-arn ARN [--action ACTION] [--resource-arn ARN]"
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$POLICY_ARN" ]]; then
  echo "--policy-arn is required." >&2
  exit 2
fi

aws iam simulate-principal-policy   --policy-source-arn "$POLICY_ARN"   --action-names "$ACTION"   --resource-arns "$RESOURCE_ARN"   --query 'EvaluationResults[].{Action:EvalActionName,Decision:EvalDecision}'   --output table

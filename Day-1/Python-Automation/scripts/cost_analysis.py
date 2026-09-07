#!/usr/bin/env python3
"""Summarize AWS costs using Cost Explorer."""

from __future__ import annotations

import argparse
import json

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def main() -> int:
    """Run a cost summary."""
    parser = argparse.ArgumentParser(
        description="Summarize AWS unblended cost for a date range."
    )
    parser.add_argument("--start", required=True, help="YYYY-MM-DD inclusive")
    parser.add_argument("--end", required=True, help="YYYY-MM-DD exclusive")
    parser.add_argument("--service", help="Optional AWS service filter")
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)

    try:
        ce = get_client("ce", "us-east-1")
        request = {
            "TimePeriod": {"Start": args.start, "End": args.end},
            "Granularity": "MONTHLY",
            "Metrics": ["UnblendedCost"],
        }
        if args.service:
            request["Filter"] = {
                "Dimensions": {
                    "Key": "SERVICE",
                    "Values": [args.service],
                }
            }

        response = call_with_retry(
            ce.get_cost_and_usage,
            logger=logger,
            **request,
        )
        print(json.dumps(response.get("ResultsByTime", []), indent=2, default=str))
        return 0
    except (ClientError, BotoCoreError):
        logger.error("Cost analysis failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

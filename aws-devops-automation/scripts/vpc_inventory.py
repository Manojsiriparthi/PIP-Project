#!/usr/bin/env python3
"""Discover VPCs and basic network metadata."""

from __future__ import annotations

import argparse
import json

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def main() -> int:
    """Run VPC inventory."""
    parser = argparse.ArgumentParser(description="Inventory VPCs.")
    parser.add_argument("--region", required=True)
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)

    try:
        ec2 = get_client("ec2", args.region)
        response = call_with_retry(ec2.describe_vpcs, logger=logger)

        data = [
            {
                "vpc_id": vpc.get("VpcId"),
                "cidr": vpc.get("CidrBlock"),
                "state": vpc.get("State"),
                "is_default": vpc.get("IsDefault"),
            }
            for vpc in response.get("Vpcs", [])
        ]
        print(json.dumps(data, indent=2, default=str))
        return 0
    except (ClientError, BotoCoreError):
        logger.error("VPC inventory failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Discover EC2 instances in one AWS account/region."""

from __future__ import annotations

import argparse
import logging
from typing import Any

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Inventory EC2 instances in an AWS region."
    )
    parser.add_argument("--region", required=True, help="AWS region")
    parser.add_argument(
        "--output",
        choices=("text", "json"),
        default="text",
        help="Output format",
    )
    return parser.parse_args()


def collect_instances(ec2: Any) -> list[dict[str, Any]]:
    """Collect all EC2 instances using pagination."""
    paginator = ec2.get_paginator("describe_instances")
    instances = []

    for page in paginator.paginate():
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                name = next(
                    (
                        tag["Value"]
                        for tag in instance.get("Tags", [])
                        if tag.get("Key") == "Name"
                    ),
                    "",
                )
                instances.append(
                    {
                        "instance_id": instance.get("InstanceId"),
                        "name": name,
                        "instance_type": instance.get("InstanceType"),
                        "state": instance.get("State", {}).get("Name"),
                        "private_ip": instance.get("PrivateIpAddress"),
                        "availability_zone": instance.get(
                            "Placement", {}
                        ).get("AvailabilityZone"),
                    }
                )

    return instances


def main() -> int:
    """Run EC2 inventory."""
    args = parse_args()
    correlation_id = configure_logging()
    logger = get_logger(correlation_id)

    try:
        ec2 = get_client("ec2", args.region)
        instances = call_with_retry(collect_instances, ec2, logger=logger)

        logger.info(
            "EC2 inventory completed",
            extra={
                "operation": "ec2_inventory",
                "region": args.region,
                "resource_count": len(instances),
            },
        )

        if args.output == "json":
            import json
            print(json.dumps(instances, indent=2, default=str))
        else:
            if not instances:
                print("No EC2 instances found.")
            for item in instances:
                print(
                    f"{item['instance_id']} | {item['name']} | "
                    f"{item['instance_type']} | {item['state']} | "
                    f"{item['private_ip']}"
                )
        return 0

    except (ClientError, BotoCoreError) as exc:
        logger.error(
            "EC2 inventory failed",
            exc_info=True,
            extra={"operation": "ec2_inventory", "region": args.region},
        )
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

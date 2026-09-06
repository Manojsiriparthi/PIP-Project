#!/usr/bin/env python3
"""Multi-account EC2/RDS/VPC discovery using asyncio and threads."""

from __future__ import annotations

import argparse
import asyncio
import json
from concurrent.futures import ThreadPoolExecutor
from typing import Any

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import (
    assume_role_session,
    extract_error,
    get_client,
    get_session,
)
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Discover EC2, RDS and VPC resources across AWS accounts."
    )
    parser.add_argument("--region", required=True, help="AWS region")
    parser.add_argument(
        "--account",
        action="append",
        required=True,
        help="AWS account ID; repeat for multiple accounts",
    )
    parser.add_argument(
        "--role-name",
        default="ResourceDiscoveryRole",
        help="Cross-account IAM role name",
    )
    parser.add_argument(
        "--output",
        choices=("text", "json"),
        default="text",
        help="Output format",
    )
    parser.add_argument(
        "--max-workers",
        type=int,
        default=6,
        help="Maximum concurrent AWS tasks",
    )
    return parser.parse_args()


def discover_account(
    account_id: str,
    region: str,
    role_name: str,
    caller_account_id: str,
) -> dict[str, Any]:
    """Discover EC2, RDS and VPC resources for one account."""
    session = get_session(region)

    if account_id != caller_account_id:
        role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
        session = assume_role_session(role_arn, region, session)

    ec2 = get_client("ec2", region, session)
    rds = get_client("rds", region, session)

    result: dict[str, Any] = {
        "account_id": account_id,
        "region": region,
        "ec2": [],
        "rds": [],
        "vpcs": [],
    }

    try:
        ec2_pages = call_with_retry(
            lambda: list(ec2.get_paginator("describe_instances").paginate()),
        )
        for page in ec2_pages:
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):
                    result["ec2"].append(
                        {
                            "instance_id": instance.get("InstanceId"),
                            "state": instance.get("State", {}).get("Name"),
                            "instance_type": instance.get("InstanceType"),
                        }
                    )

        rds_pages = call_with_retry(
            lambda: list(rds.get_paginator("describe_db_instances").paginate()),
        )
        for page in rds_pages:
            for db in page.get("DBInstances", []):
                result["rds"].append(
                    {
                        "db_identifier": db.get("DBInstanceIdentifier"),
                        "engine": db.get("Engine"),
                        "status": db.get("DBInstanceStatus"),
                        "instance_class": db.get("DBInstanceClass"),
                    }
                )

        vpcs = call_with_retry(ec2.describe_vpcs)["Vpcs"]
        result["vpcs"] = [
            {
                "vpc_id": vpc.get("VpcId"),
                "cidr": vpc.get("CidrBlock"),
                "state": vpc.get("State"),
            }
            for vpc in vpcs
        ]

        return result

    except (ClientError, BotoCoreError):
        raise


async def discover_all(
    accounts: list[str],
    region: str,
    role_name: str,
    caller_account_id: str,
    max_workers: int,
) -> list[dict[str, Any]]:
    """Run blocking boto3 account scans concurrently."""
    loop = asyncio.get_running_loop()

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        tasks = [
            loop.run_in_executor(
                executor,
                discover_account,
                account_id,
                region,
                role_name,
                caller_account_id,
            )
            for account_id in accounts
        ]
        return await asyncio.gather(*tasks, return_exceptions=True)


async def async_main(args: argparse.Namespace, correlation_id: str) -> int:
    """Async entry point."""
    logger = get_logger(correlation_id)
    caller = get_session(args.region).client("sts", region_name=args.region)
    identity = caller.get_caller_identity()
    caller_account_id = identity["Account"]

    results = await discover_all(
        args.account,
        args.region,
        args.role_name,
        caller_account_id,
        args.max_workers,
    )

    normalized: list[dict[str, Any]] = []
    for account_id, result in zip(args.account, results):
        if isinstance(result, Exception):
            code, message = extract_error(result)
            logger.error(
                "Account discovery failed",
                extra={
                    "operation": "multi_account_discovery",
                    "account_id": account_id,
                    "region": args.region,
                    "error_code": code,
                },
            )
            normalized.append(
                {
                    "account_id": account_id,
                    "error": {"code": code, "message": message},
                }
            )
        else:
            normalized.append(result)

    logger.info(
        "Multi-account discovery completed",
        extra={
            "operation": "multi_account_discovery",
            "region": args.region,
            "resource_count": len(normalized),
        },
    )

    if args.output == "json":
        print(json.dumps(normalized, indent=2, default=str))
    else:
        for item in normalized:
            print(f"\nAccount: {item['account_id']}")
            if "error" in item:
                print(f"  ERROR: {item['error']['code']}: {item['error']['message']}")
                continue
            print(f"  EC2: {len(item['ec2'])}")
            print(f"  RDS: {len(item['rds'])}")
            print(f"  VPC: {len(item['vpcs'])}")

    return 0


def main() -> int:
    """Run multi-account discovery."""
    args = parse_args()
    correlation_id = configure_logging()
    try:
        return asyncio.run(async_main(args, correlation_id))
    except (ClientError, BotoCoreError) as exc:
        logger = get_logger(correlation_id)
        logger.error(
            "Discovery failed",
            exc_info=True,
            extra={"operation": "multi_account_discovery"},
        )
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

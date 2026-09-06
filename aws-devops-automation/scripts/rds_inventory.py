#!/usr/bin/env python3
"""Discover RDS instances."""

from __future__ import annotations

import argparse
import json

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def main() -> int:
    """Run RDS inventory."""
    parser = argparse.ArgumentParser(description="Inventory RDS instances.")
    parser.add_argument("--region", required=True)
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)

    try:
        rds = get_client("rds", args.region)

        def collect():
            paginator = rds.get_paginator("describe_db_instances")
            result = []
            for page in paginator.paginate():
                result.extend(
                    {
                        "identifier": db.get("DBInstanceIdentifier"),
                        "engine": db.get("Engine"),
                        "status": db.get("DBInstanceStatus"),
                        "instance_class": db.get("DBInstanceClass"),
                        "availability_zone": db.get("AvailabilityZone"),
                    }
                    for db in page.get("DBInstances", [])
                )
            return result

        data = call_with_retry(collect, logger=logger)
        print(json.dumps(data, indent=2, default=str))
        return 0
    except (ClientError, BotoCoreError):
        logger.error("RDS inventory failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

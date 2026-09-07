#!/usr/bin/env python3
"""Safely identify and optionally delete old EBS snapshots."""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def main() -> int:
    """Run snapshot management in dry-run mode unless --execute is supplied."""
    parser = argparse.ArgumentParser(
        description="Find old EBS snapshots; deletion requires --execute."
    )
    parser.add_argument("--region", required=True)
    parser.add_argument("--older-than", type=int, default=90)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)
    dry_run = not args.execute

    try:
        ec2 = get_client("ec2", args.region)
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.older_than)

        response = call_with_retry(
            ec2.describe_snapshots,
            OwnerIds=["self"],
            logger=logger,
        )

        candidates = []
        for snapshot in response.get("Snapshots", []):
            started = snapshot.get("StartTime")
            if started and started < cutoff:
                candidates.append(snapshot)

        for snapshot in candidates:
            snapshot_id = snapshot["SnapshotId"]
            if dry_run:
                print(f"DRY-RUN: would delete {snapshot_id}")
            else:
                call_with_retry(
                    ec2.delete_snapshot,
                    SnapshotId=snapshot_id,
                    logger=logger,
                )
                print(f"DELETED: {snapshot_id}")

        logger.info(
            "Snapshot management completed",
            extra={
                "operation": "snapshot_manager",
                "region": args.region,
                "resource_count": len(candidates),
            },
        )
        return 0
    except (ClientError, BotoCoreError):
        logger.error("Snapshot management failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

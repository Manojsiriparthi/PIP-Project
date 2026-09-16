#!/usr/bin/env python3
"""Safely identify and optionally deregister old self-owned AMIs."""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry


def main() -> int:
    """Run AMI cleanup in dry-run mode unless --execute is supplied."""
    parser = argparse.ArgumentParser(
        description="Find old self-owned AMIs; deletion requires --execute."
    )
    parser.add_argument("--region", required=True)
    parser.add_argument("--older-than", type=int, default=90)
    parser.add_argument("--dry-run", action="store_true", default=False)
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Actually deregister matching AMIs. Overrides dry-run.",
    )
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)
    dry_run = not args.execute

    try:
        ec2 = get_client("ec2", args.region)
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.older_than)

        response = call_with_retry(
            ec2.describe_images,
            Owners=["self"],
            logger=logger,
        )

        candidates = []
        for image in response.get("Images", []):
            created = image.get("CreationDate")
            if not created:
                continue
            created_dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
            if created_dt < cutoff:
                candidates.append(image)

        for image in candidates:
            image_id = image["ImageId"]
            if dry_run:
                print(f"DRY-RUN: would deregister {image_id}")
            else:
                call_with_retry(
                    ec2.deregister_image,
                    ImageId=image_id,
                    logger=logger,
                )
                print(f"DELETED: deregistered {image_id}")

        logger.info(
            "AMI cleanup completed",
            extra={
                "operation": "ami_cleanup",
                "region": args.region,
                "resource_count": len(candidates),
            },
        )
        return 0
    except (ClientError, BotoCoreError):
        logger.error("AMI cleanup failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

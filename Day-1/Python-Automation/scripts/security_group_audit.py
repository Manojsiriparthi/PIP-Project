#!/usr/bin/env python3
"""Audit security groups for publicly exposed sensitive ports."""

from __future__ import annotations

import argparse
import json

from botocore.exceptions import BotoCoreError, ClientError

from common.aws_utils import get_client
from common.logging_utils import configure_logging, get_logger
from common.retry_utils import call_with_retry

SENSITIVE_PORTS = {22, 3389, 3306, 5432, 6379, 27017}


def main() -> int:
    """Run the security group audit."""
    parser = argparse.ArgumentParser(
        description="Find security-group ingress rules open to the internet."
    )
    parser.add_argument("--region", required=True)
    args = parser.parse_args()

    correlation_id = configure_logging()
    logger = get_logger(correlation_id)

    try:
        ec2 = get_client("ec2", args.region)
        response = call_with_retry(
            ec2.describe_security_groups,
            logger=logger,
        )

        findings = []
        for group in response.get("SecurityGroups", []):
            for permission in group.get("IpPermissions", []):
                from_port = permission.get("FromPort")
                to_port = permission.get("ToPort")

                for ip_range in permission.get("IpRanges", []):
                    if ip_range.get("CidrIp") != "0.0.0.0/0":
                        continue

                    exposed = (
                        from_port is None
                        or to_port is None
                        or any(
                            from_port <= port <= to_port
                            for port in SENSITIVE_PORTS
                        )
                    )

                    if exposed:
                        findings.append(
                            {
                                "group_id": group.get("GroupId"),
                                "group_name": group.get("GroupName"),
                                "protocol": permission.get("IpProtocol"),
                                "from_port": from_port,
                                "to_port": to_port,
                                "source": ip_range.get("CidrIp"),
                                "risk": "PUBLIC_INGRESS",
                            }
                        )

        logger.info(
            "Security group audit completed",
            extra={
                "operation": "security_group_audit",
                "region": args.region,
                "resource_count": len(findings),
            },
        )
        print(json.dumps(findings, indent=2, default=str))
        return 0
    except (ClientError, BotoCoreError):
        logger.error("Security group audit failed", exc_info=True)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

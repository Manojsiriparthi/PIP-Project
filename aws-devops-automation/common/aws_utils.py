"""Reusable AWS helpers."""

from __future__ import annotations

from typing import Any

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError


def get_session(region: str | None = None) -> boto3.Session:
    """Create a boto3 session using the standard credential provider chain."""
    return boto3.Session(region_name=region)


def get_client(
    service: str,
    region: str,
    session: boto3.Session | None = None,
) -> Any:
    """Create an AWS client with sensible SDK retry configuration."""
    session = session or get_session(region)
    config = Config(
        retries={"mode": "standard", "max_attempts": 5},
        connect_timeout=10,
        read_timeout=60,
    )
    return session.client(service, region_name=region, config=config)


def assume_role_session(
    role_arn: str,
    region: str,
    source_session: boto3.Session | None = None,
) -> boto3.Session:
    """Assume a cross-account role and return a temporary-credential session."""
    source_session = source_session or get_session(region)
    sts = source_session.client("sts", region_name=region)

    response = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName="pip-resource-discovery",
    )
    credentials = response["Credentials"]

    return boto3.Session(
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
        region_name=region,
    )


def extract_error(exc: Exception) -> tuple[str, str]:
    """Extract a stable error code/message from AWS or SDK exceptions."""
    if isinstance(exc, ClientError):
        error = exc.response.get("Error", {})
        return error.get("Code", "ClientError"), error.get(
            "Message", str(exc)
        )

    if isinstance(exc, BotoCoreError):
        return exc.__class__.__name__, str(exc)

    return exc.__class__.__name__, str(exc)

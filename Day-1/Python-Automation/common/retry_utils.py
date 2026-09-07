"""Retry helpers for transient AWS API failures."""

from __future__ import annotations

import random
import time
from collections.abc import Callable
from typing import Any, TypeVar

from botocore.exceptions import ClientError

T = TypeVar("T")


RETRYABLE_CODES = {
    "Throttling",
    "ThrottlingException",
    "RequestLimitExceeded",
    "TooManyRequestsException",
    "ServiceUnavailable",
    "InternalError",
    "InternalFailure",
    "SlowDown",
}


def is_retryable_aws_error(exc: Exception) -> bool:
    """Return True when an AWS exception is likely transient."""
    if isinstance(exc, ClientError):
        code = exc.response.get("Error", {}).get("Code", "")
        return code in RETRYABLE_CODES
    return False


def call_with_retry(
    operation: Callable[..., T],
    *args: Any,
    retries: int = 4,
    base_delay: float = 1.0,
    max_delay: float = 30.0,
    logger: Any = None,
    **kwargs: Any,
) -> T:
    """Call an operation with exponential backoff and jitter."""
    attempt = 0

    while True:
        try:
            return operation(*args, **kwargs)
        except Exception as exc:
            if not is_retryable_aws_error(exc) or attempt >= retries:
                raise

            delay = min(max_delay, base_delay * (2 ** attempt))
            jitter = random.uniform(0, delay * 0.25)
            sleep_for = delay + jitter

            if logger:
                logger.warning(
                    "Transient AWS error; retrying",
                    extra={
                        "operation": getattr(operation, "__name__", "aws_operation"),
                        "retry_attempt": attempt + 1,
                        "retry_delay_seconds": round(sleep_for, 2),
                    },
                )

            time.sleep(sleep_for)
            attempt += 1

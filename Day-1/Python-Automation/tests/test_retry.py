"""Tests for retry behavior."""

from unittest.mock import Mock

import pytest
from botocore.exceptions import ClientError

from common.retry_utils import call_with_retry


def throttling_error():
    return ClientError(
        {
            "Error": {
                "Code": "ThrottlingException",
                "Message": "Rate exceeded",
            }
        },
        "DescribeInstances",
    )


def test_retry_then_success(monkeypatch):
    operation = Mock(side_effect=[throttling_error(), "success"])
    monkeypatch.setattr("common.retry_utils.time.sleep", lambda _: None)

    assert call_with_retry(operation, retries=2) == "success"
    assert operation.call_count == 2


def test_non_retryable_error_raises():
    operation = Mock(
        side_effect=ClientError(
            {
                "Error": {
                    "Code": "AccessDenied",
                    "Message": "Denied",
                }
            },
            "DescribeInstances",
        )
    )

    with pytest.raises(ClientError):
        call_with_retry(operation, retries=2)

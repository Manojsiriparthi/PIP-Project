"""Structured JSON logging utilities."""

from __future__ import annotations

import json
import logging
import sys
import uuid
from datetime import datetime, timezone
from typing import Any


class JsonFormatter(logging.Formatter):
    """Format log records as JSON."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "severity": record.levelname,
            "correlation_id": getattr(record, "correlation_id", "unknown"),
            "message": record.getMessage(),
        }

        for key in ("operation", "account_id", "region", "resource_count"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, default=str)


def configure_logging(level: int = logging.INFO) -> str:
    """Configure root logging and return a correlation ID."""
    correlation_id = str(uuid.uuid4())
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level)

    logging.LoggerAdapter(
        logging.getLogger(__name__),
        {"correlation_id": correlation_id},
    )
    return correlation_id


def get_logger(correlation_id: str) -> logging.LoggerAdapter:
    """Return a logger adapter carrying the execution correlation ID."""
    return logging.LoggerAdapter(
        logging.getLogger(__name__),
        {"correlation_id": correlation_id},
    )

# AWS DevOps Automation — PIP Task

This project implements the Python/Boto3 requirements from the PIP task:

1. Multi-account resource discovery (EC2, RDS, VPC)
2. Concurrent AWS operations using `asyncio` + `concurrent.futures`
3. Structured JSON logging with timestamp, correlation ID and severity
4. 5+ production-oriented scripts
5. Retry with exponential backoff and jitter
6. AWS SDK error handling (`ClientError`, `BotoCoreError`, throttling recovery)
7. CLI parsing with `argparse` and help documentation
8. Dry-run protection for destructive operations
9. No hardcoded AWS credentials

## Scripts

- `resource_discovery.py` — EC2/RDS/VPC discovery across one or more accounts
- `ec2_inventory.py` — EC2 inventory
- `cost_analysis.py` — Cost Explorer summary (requires Cost Explorer access)
- `security_group_audit.py` — finds risky public security-group rules
- `ami_cleanup.py` — identifies old AMIs and deregisters only with `--execute`
- `snapshot_manager.py` — identifies old EBS snapshots and deletes only with `--execute`

## Security model

Credentials are never stored in source code. Boto3 uses the normal AWS credential provider chain. For cross-account discovery, the script uses STS `AssumeRole` and temporary credentials.

For a lab, use read-only permissions for discovery. Test destructive scripts with `--dry-run` first.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Verify credentials:

```bash
aws sts get-caller-identity
```

## Examples

Single-account EC2:

```bash
python scripts/ec2_inventory.py --region ap-south-1
```

Multi-account EC2/RDS/VPC discovery:

```bash
python scripts/resource_discovery.py \
  --region ap-south-1 \
  --account 111111111111 \
  --account 222222222222 \
  --role-name ResourceDiscoveryRole
```

The current caller account can be scanned without AssumeRole. Other accounts require a role that trusts the caller account.

JSON output:

```bash
python scripts/resource_discovery.py \
  --region ap-south-1 \
  --account 111111111111 \
  --account 222222222222 \
  --output json
```

Security group audit:

```bash
python scripts/security_group_audit.py --region ap-south-1
```

Cost summary:

```bash
python scripts/cost_analysis.py --start 2026-08-01 --end 2026-09-01
```

AMI cleanup — safe mode:

```bash
python scripts/ami_cleanup.py \
  --region ap-south-1 \
  --older-than 90 \
  --dry-run
```

Actual execution requires an explicit flag:

```bash
python scripts/ami_cleanup.py \
  --region ap-south-1 \
  --older-than 90 \
  --execute
```

Snapshot manager:

```bash
python scripts/snapshot_manager.py \
  --region ap-south-1 \
  --older-than 90 \
  --dry-run
```

## Retry design

Transient failures such as throttling are retried with exponential backoff plus random jitter. Non-transient errors such as access denied are logged and returned without blind retries.

## Error handling note

Boto3 service API failures are normally surfaced as `botocore.exceptions.ClientError`, with the AWS service error code available in `exc.response["Error"]["Code"]`. SDK/network failures are represented by `BotoCoreError` subclasses. The code handles both categories rather than assuming a non-existent generic `ServiceError` class.

## Pylint

Run:

```bash
pylint common scripts
```

Target: `> 8.0/10`.

## Tests

```bash
pytest -q
```

## PIP evidence to capture

1. `aws sts get-caller-identity`
2. `python scripts/resource_discovery.py --help`
3. Multi-account discovery output
4. JSON logs containing timestamp/correlation_id/severity
5. Retry/throttling log demonstration
6. `--dry-run` showing no destructive API is called
7. `pylint common scripts`
8. `pytest -q`
9. GitHub repository showing 5+ scripts and documentation

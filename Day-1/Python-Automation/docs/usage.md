# Usage and PIP Demonstration

## 1. Credential proof

```bash
aws sts get-caller-identity
```

Do not put the output credentials in GitHub.

## 2. CLI proof

```bash
python scripts/resource_discovery.py --help
```

## 3. Multi-account proof

Run against your account and a friend's account after the friend creates
a read-only `ResourceDiscoveryRole` that trusts your AWS account.

```bash
python scripts/resource_discovery.py \
  --region ap-south-1 \
  --account YOUR_ACCOUNT_ID \
  --account FRIEND_ACCOUNT_ID \
  --role-name ResourceDiscoveryRole
```

## 4. JSON logging proof

Every script initializes structured logging. Capture a successful run showing:

- timestamp
- severity
- correlation_id
- operation
- region/resource count where available

## 5. Retry proof

Unit tests simulate an AWS throttling error and verify a retry occurs.

```bash
pytest -q
```

## 6. Dry-run proof

```bash
python scripts/ami_cleanup.py \
  --region ap-south-1 \
  --older-than 90 \
  --dry-run
```

or simply omit `--execute`; destructive action is disabled by default.

## 7. Quality proof

```bash
pylint common scripts
```

Target the task requirement: greater than 8.0/10.

## 8. What to tell the reviewer

"I built a reusable Boto3 automation library with structured JSON logs,
correlation IDs, AWS SDK error handling, retry with exponential backoff and
jitter, argparse help, multi-account STS AssumeRole support, concurrency using
asyncio and ThreadPoolExecutor, and dry-run protection for destructive
operations. I also added tests and documentation."

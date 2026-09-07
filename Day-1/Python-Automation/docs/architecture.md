# Architecture

## Single-account flow

```text
CLI
 |
 +--> boto3 Session
       |
       +--> EC2
       +--> RDS
       +--> VPC
```

## Multi-account flow

```text
Operator / CI
     |
     v
Main AWS identity
     |
     v
STS AssumeRole
     |
     +----> Account A / ResourceDiscoveryRole
     |
     +----> Account B / ResourceDiscoveryRole
     |
     +----> Account C / ResourceDiscoveryRole
              |
              +--> EC2
              +--> RDS
              +--> VPC
```

The discovery application uses `asyncio` to coordinate tasks and
`ThreadPoolExecutor` to run blocking Boto3 operations concurrently.

## Safety

- Credentials are supplied by AWS's credential provider chain.
- Cross-account access uses temporary STS credentials.
- Discovery is read-only.
- Destructive scripts default to dry-run behavior.
- Actual deletion/deregistration requires `--execute`.

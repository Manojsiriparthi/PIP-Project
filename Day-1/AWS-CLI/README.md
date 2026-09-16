# Day 1 Task 3 - AWS CLI Automation (Linux/Bash)

This repository is the Linux/Bash implementation of Day 1 Task 3.

Covers:
- 10+ AWS CLI scripts
- Bulk EC2 tagging and restart
- EC2 security-group changes
- VPC analysis
- IAM policy simulation
- JMESPath queries
- RDS queries across regions
- S3 bucket-policy auditing
- Instance termination with dry-run
- EBS volume snapshots
- Tag enforcement
- Parallel processing
- CloudWatch Logs Insights queries
- Retry/error-handling wrapper
- Documentation

## Requirements

AWS CLI v2 and Bash.

Verify:

```bash
aws --version
aws sts get-caller-identity
```

Use IAM roles, AWS SSO, or AWS CLI profiles. Never hardcode access keys.

## Safety

Destructive scripts use dry-run by default where applicable. Review output before using `--execute`.

Examples:

```bash
./scripts/ec2_bulk_tag.sh --region ap-south-1 --tag Environment=Dev
./scripts/ec2_bulk_restart.sh --region ap-south-1 --tag Environment=Dev
./scripts/ec2_terminate.sh --region ap-south-1 --tag Environment=Dev
./scripts/volume_snapshot.sh --region ap-south-1 --tag Environment=Dev
```

The commands above only show what would happen. Add `--execute` only after reviewing the targets.

## Script list

1. ec2_inventory.sh
2. ec2_filter_by_tag.sh
3. ec2_bulk_tag.sh
4. ec2_bulk_restart.sh
5. ec2_sg_change.sh
6. ec2_terminate.sh
7. vpc_analysis.sh
8. iam_policy_simulate.sh
9. rds_multi_region.sh
10. s3_policy_audit.sh
11. volume_snapshot.sh
12. tag_enforcement.sh
13. parallel_ec2.sh
14. aws_retry_wrapper.sh
15. cloudwatch_query_examples.sh

## Suggested PIP demo order

```text
AWS identity
  -> EC2 inventory
  -> JMESPath tag filtering
  -> RDS multi-region
  -> S3 policy audit
  -> VPC analysis
  -> IAM policy simulation
  -> dry-run EC2 tag/restart/terminate
  -> dry-run snapshot
  -> parallel processing
  -> retry wrapper
  -> CloudWatch Logs Insights
  -> GitHub documentation
```

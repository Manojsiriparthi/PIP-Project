# Day 1 Task 3 Requirement Mapping

| Requirement | Evidence |
|---|---|
| 10+ AWS CLI scripts | 15 Bash scripts under `scripts/` |
| Bulk EC2 tag | `ec2_bulk_tag.sh` |
| Bulk EC2 restart | `ec2_bulk_restart.sh` |
| Security group changes | `ec2_sg_change.sh` |
| VPC analysis | `vpc_analysis.sh` |
| IAM policy simulation | `iam_policy_simulate.sh` |
| JMESPath | `jmespath/queries.md` and CLI `--query` usage |
| RDS across regions | `rds_multi_region.sh` |
| S3 bucket policy audit | `s3_policy_audit.sh` |
| Instance termination | `ec2_terminate.sh` with dry-run |
| Volume snapshots | `volume_snapshot.sh` |
| Tag enforcement | `tag_enforcement.sh` |
| Parallel processing | `parallel_ec2.sh` |
| CloudWatch Logs Insights | `cloudwatch/logs_insights_queries.md` |
| Retry mechanism | `aws_retry_wrapper.sh` |
| Error handling | `set -euo pipefail`, explicit exit checks and warnings |
| Documentation | README, usage, mapping and GitHub Wiki |

## PIP evidence to capture

- `aws sts get-caller-identity`
- Script `--help` output
- EC2 inventory
- EC2 tag filtering
- RDS output from two regions
- S3 policy audit
- VPC analysis
- IAM simulation result
- Dry-run output
- Parallel processing output
- Retry wrapper output
- CloudWatch Logs Insights result

# EC2 Task 1 – Short Interview Notes

## Why did you create 8 instances?

I created eight instances because the requirement is to benchmark multiple EC2 families. I distributed them as two instances across each of four AWS regions.

## Why four regions?

Four regions demonstrate multi-region Terraform provisioning and allow regional performance and latency characteristics to be compared.

## Why T4g?

T4g uses AWS Graviton/ARM64 and is useful for cost-efficient burstable workloads. It also demonstrates architecture-aware AMI selection.

## Why T3?

T3 is an x86 burstable instance family suitable for workloads with variable CPU demand.

## Why M6i?

M6i is general-purpose and provides a balanced CPU and memory profile for common application workloads.

## Why C6i?

C6i is compute optimized and is suitable for CPU-intensive workloads.

## Why R6i?

R6i is memory optimized and is suitable for workloads that need higher memory capacity.

## Why different AMIs?

T4g uses ARM64, while T3/M6i/C6i/R6i use x86_64 in this design. Terraform selects the correct Amazon Linux 2023 AMI through AWS SSM Parameter Store.

## Why Terraform modules?

I wrote the EC2 logic once as a reusable module and called it from four region-specific provider configurations. This reduces duplicate code and improves consistency.

## Why dev/test/prod variables?

I keep environment-specific values in separate `.tfvars` files. The same Terraform code can therefore be planned or deployed for dev, test, or prod.

## Why tags?

Tags make resources easy to identify, filter, report, and manage. Every instance has Project, Email, and Name tags.

## Why an IAM instance profile?

An instance profile attaches an IAM role to EC2 and provides temporary credentials without storing long-lived access keys on the server.

## How did you implement least privilege?

The role has explicit permissions for `ec2:DescribeTags` and `cloudwatch:PutMetricData`. I did not use a wildcard action such as `Action: "*"`.

## What is the purpose of benchmarking?

Benchmarking lets us compare CPU, memory, network, latency, and cost/performance across instance families and select the appropriate instance type for a workload.

## What would you do before production?

I would use a dedicated VPC/subnet design, security groups, centralized logging/monitoring, remote Terraform state, stronger IAM controls, and a controlled benchmark workload.

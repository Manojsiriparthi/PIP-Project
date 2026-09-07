# EC2 Task 1 – Detailed Explanation

## 1. Why launch 8 EC2 instances?

The PIP requirement asks for at least eight EC2 instances across multiple instance families. I created exactly eight and distributed them evenly as two instances in each of four regions.

```text
ap-south-1      → 2
us-east-1       → 2
eu-west-1       → 2
ap-southeast-1  → 2
--------------------
Total           → 8
```

This provides enough resources to compare different instance families and regional behavior.

## 2. Why use four AWS regions?

Multiple regions allow me to demonstrate multi-region Infrastructure as Code. It also allows regional latency and performance characteristics to be compared.

Terraform provider aliases are used so the same module can create resources in different regions.

## 3. Why use T4g, T3, M6i, C6i and R6i?

Each family is designed for a different workload profile:

| Family | Typical use |
|---|---|
| T4g | ARM/Graviton burstable workloads |
| T3 | x86 burstable workloads |
| M6i | General-purpose workloads |
| C6i | CPU/compute-intensive workloads |
| R6i | Memory-intensive workloads |

A benchmark can therefore compare CPU, memory, network, application response time, and cost/performance.

## 4. Why separate ARM64 and x86 AMIs?

T4g uses AWS Graviton processors and requires an ARM64-compatible AMI. The other selected families use x86_64 in this task.

The Terraform module automatically selects the Amazon Linux 2023 SSM parameter for the required architecture.

This prevents an incompatible AMI from being assigned to a T4g instance.

## 5. Why use Terraform modules?

The networking-independent EC2 logic is written once in `modules/ec2_benchmark`.

The root configuration calls the same module four times with different AWS provider aliases.

This avoids duplicate EC2 resource code and keeps the implementation reusable.

## 6. Why use dev/test/prod variable files?

The code remains the same while the variable file selects the environment.

```text
envs/dev.tfvars
envs/test.tfvars
envs/prod.tfvars
```

This is a common Infrastructure as Code pattern because environment-specific values are separated from reusable infrastructure logic.

## 7. Why use tags?

Every EC2 instance receives:

```text
Project = PIP
Email   = siriparthi.manojkumar@gmail.com
Name    = unique instance name
```

Tags make resources easier to identify, filter, report, and manage.

## 8. Why use an IAM instance profile?

An instance profile attaches the IAM role to EC2. Applications on the instance can then obtain temporary credentials from the EC2 metadata service instead of storing long-lived access keys.

This is safer than putting AWS access keys in scripts or configuration files.

## 9. How is least privilege implemented?

The role does not use a broad administrator policy or:

```text
Action = "*"
```

It allows only:

```text
ec2:DescribeTags
cloudwatch:PutMetricData
```

The CloudWatch action is additionally constrained to:

```text
PIP/EC2Benchmark
```

The role is intended for benchmark telemetry rather than general AWS administration.

## 10. Why use the default VPC here?

This task focuses on EC2 multi-region provisioning. The separate VPC task covers production VPC design.

Using the default VPC keeps this task smaller and allows the EC2 benchmark to be tested without duplicating VPC infrastructure.

For a production implementation, I would normally provide the VPC/subnet IDs explicitly and avoid depending on default VPCs.

## 11. How would I benchmark the instances?

I would run the same workload against each instance type and collect:

```text
CPU utilization
Memory utilization
Disk I/O
Network throughput
Application latency
Regional latency
Cost
```

The workload should be consistent so the results are comparable.

## 12. Cost consideration

Larger instance types can create significant costs. I would review `terraform plan` before applying and destroy the benchmark environment after testing.

```bash
terraform destroy -var-file=envs/dev.tfvars
```

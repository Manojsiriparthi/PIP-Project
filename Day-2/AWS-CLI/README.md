# Day 2 EC2 Task 1 – Multi-Region Benchmark

## Requirement

Launch **8 EC2 instances across four AWS regions**, with two instances per region, covering the required families:

- T4g
- T3
- M6i
- C6i
- R6i

Everything is provisioned with Terraform.

## Instance layout

| Region | Instance 1 | Instance 2 |
|---|---|---|
| `ap-south-1` | `t4g.micro` | `t3.micro` |
| `us-east-1` | `m6i.large` | `c6i.large` |
| `eu-west-1` | `r6i.large` | `t4g.micro` |
| `ap-southeast-1` | `t3.micro` | `m6i.large` |

**Total: 8 instances.**

## Required tags

Every EC2 instance receives:

```text
Project = PIP
Email   = siriparthi.manojkumar@gmail.com
Name    = unique instance name
```

## ARM64 vs x86_64 AMI handling

T4g is based on AWS Graviton and uses ARM64. T3/M6i/C6i/R6i in this task use x86_64.

The module selects Amazon Linux 2023 AMIs from AWS Systems Manager Parameter Store:

```text
ARM64  → /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64
x86_64 → /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
```

This avoids hardcoded AMI IDs and automatically uses the current regional AMI parameter.

## Least-privilege IAM

Terraform creates an EC2 role and instance profile.

The role explicitly allows:

```text
ec2:DescribeTags
cloudwatch:PutMetricData
```

The CloudWatch permission is restricted to the `PIP/EC2Benchmark` namespace.

There is no `Action = "*"`.

`Resource = "*"` is used only where these AWS API permissions do not provide a useful resource-level ARN. The permission set itself remains limited to the required actions.

## Environment variables

Three variable files are included:

```text
envs/dev.tfvars
envs/test.tfvars
envs/prod.tfvars
```

The same Terraform code can therefore be planned for dev, test, or prod without changing the module.

## Default VPC prerequisite

To keep this EC2 task focused on EC2 provisioning rather than VPC creation, the module uses the **default VPC** and its first subnet in each region.

Before applying, verify that the four regions have a default VPC and at least one subnet.

If a default VPC is missing, create/choose a VPC and subnet or adapt the module to the VPC created in the separate VPC task.

## Cost warning

`m6i.large`, `c6i.large`, and `r6i.large` are not free-tier-sized in many accounts. Running eight instances across four regions can incur charges.

Always run and review:

```bash
terraform plan -var-file=envs/dev.tfvars
```

before:

```bash
terraform apply -var-file=envs/dev.tfvars
```

Destroy the lab resources when finished:

```bash
terraform destroy -var-file=envs/dev.tfvars
```

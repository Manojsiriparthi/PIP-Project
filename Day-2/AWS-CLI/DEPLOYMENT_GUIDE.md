# Deployment Guide

## 1. Prerequisites

On the Linux EC2/Cloud Shell/terminal where Terraform runs:

```bash
terraform version
aws sts get-caller-identity
```

The AWS identity needs permissions to create the EC2 resources and IAM role/instance profile used by this project.

## 2. Initialize

From the project root:

```bash
terraform fmt -recursive
terraform init
terraform validate
```

## 3. Verify regions

Check that each region has a default VPC:

```bash
for r in ap-south-1 us-east-1 eu-west-1 ap-southeast-1; do
  echo "===== $r ====="
  aws ec2 describe-vpcs \
    --region "$r" \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[].VpcId' \
    --output text
done
```

If a region returns no VPC, do not apply until a suitable VPC/subnet is available.

## 4. Plan DEV

```bash
terraform plan -var-file=envs/dev.tfvars
```

Expected high-level result:

```text
8 aws_instance resources
1 IAM role
1 IAM inline policy
1 IAM instance profile
```

## 5. Apply DEV

Only after reviewing the plan:

```bash
terraform apply -var-file=envs/dev.tfvars
```

## 6. Verify

```bash
terraform output
```

Example EC2 verification:

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,Tags:Tags}' \
  --output table
```

Repeat for:

```text
us-east-1
eu-west-1
ap-southeast-1
```

## 7. Test TEST or PROD configuration

Do not create all environments at once unless that is intentionally required.

Plan a different environment separately:

```bash
terraform plan -var-file=envs/test.tfvars
```

or:

```bash
terraform plan -var-file=envs/prod.tfvars
```

## 8. Cleanup

```bash
terraform destroy -var-file=envs/dev.tfvars
```

If you applied another environment, destroy using that same variable file.

## 9. Recommended evidence screenshots

Capture:

1. `terraform fmt` and `terraform validate`
2. `terraform plan`
3. Terraform apply output
4. EC2 console showing instances
5. EC2 tags
6. IAM role policy
7. Four AWS regions
8. Terraform outputs
9. Correct ARM64 AMI for T4g
10. Correct x86_64 AMI for T3/M6i/C6i/R6i

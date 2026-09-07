# Deployment Guide

## 0. Prerequisites

- Terraform >= 1.10
- AWS CLI configured or an EC2 IAM role with sufficient permissions
- Three AZs available in `ap-south-1`
- An S3 bucket for Terraform state

## 1. Create the Terraform state bucket

From the project root:

```bash
export AWS_REGION=ap-south-1
./scripts/create-state-bucket.sh <globally-unique-state-bucket-name>
```

The script enables S3 versioning, encryption, and public-access blocking.

## 2. Configure the dev backend

Edit `envs/dev/backend.tf` and replace:

```text
REPLACE_WITH_PIP_TERRAFORM_STATE_BUCKET
```

with the state bucket created in step 1.

## 3. Deploy dev

```bash
cd envs/dev
terraform fmt -recursive
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## 4. Deploy prod separately

```bash
cd ../prod
# Replace the state bucket placeholder in backend.tf if not already done.
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Do not apply both environments unless you intentionally want both VPCs.

## 5. Verify

```bash
terraform output
aws ec2 describe-vpcs --region ap-south-1
aws ec2 describe-route-tables --region ap-south-1
aws ec2 describe-vpc-endpoints --region ap-south-1
aws ec2 describe-flow-logs --region ap-south-1
aws s3api list-buckets --query 'Buckets[].Name' --output table
```

## 6. Validate native state locking

With `use_lockfile = true`, Terraform uses an S3 lock object alongside the state object. The S3 backend documentation specifies the lock file as `<state-key>.tflock`. Do not manually delete a lock file while another Terraform operation is running.

## 7. Cost controls

Dev uses one NAT Gateway. Prod uses one per AZ. Interface endpoints and NAT Gateways can cost money. For a lab, use dev first and destroy it when finished.

## 8. Destroy

```bash
terraform plan -destroy -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars
```

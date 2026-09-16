# Replace the bucket name before terraform init. The bucket must exist already.
# Native S3 state locking is enabled with use_lockfile=true; no DynamoDB table is required.
terraform {
  backend "s3" {
    bucket       = "REPLACE_WITH_PIP_TERRAFORM_STATE_BUCKET"
    key          = "infra-vpc/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

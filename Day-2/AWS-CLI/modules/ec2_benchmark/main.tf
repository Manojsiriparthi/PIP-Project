# This project intentionally uses the AWS default VPC/subnet in each region
# to keep the EC2 task focused on multi-region instance benchmarking.
# If a region has no default VPC, create/choose a VPC and subnet before apply.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "al2023_x86_64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

locals {
  subnet_id = data.aws_subnets.default.ids[0]
}

resource "aws_instance" "this" {
  for_each = var.instances

  ami = each.value.architecture == "arm64" ? data.aws_ssm_parameter.al2023_arm64.value : data.aws_ssm_parameter.al2023_x86_64.value

  instance_type = each.value.instance_type
  subnet_id     = local.subnet_id

  iam_instance_profile = var.instance_profile_name

  tags = {
    Project = var.project_tag
    Email   = var.owner_email
    Name    = each.value.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

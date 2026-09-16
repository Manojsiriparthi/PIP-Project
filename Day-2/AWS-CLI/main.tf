terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Four fixed provider aliases allow the same module to deploy into four regions.
provider "aws" {
  alias  = "ap_south_1"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
}

# IAM is global. This role is created once and can be referenced by
# EC2 instance profiles in the four regions.
resource "aws_iam_role" "benchmark" {
  name = "${var.name_prefix}-ec2-least-privilege"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EC2AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "PIP"
    Email   = var.owner_email
    Name    = "${var.name_prefix}-ec2-least-privilege"
  }
}

resource "aws_iam_role_policy" "benchmark" {
  name = "${var.name_prefix}-metrics-policy"
  role = aws_iam_role.benchmark.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeOwnTags"
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "PublishBenchmarkMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = var.cloudwatch_namespace
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "benchmark" {
  name = "${var.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.benchmark.name

  tags = {
    Project = "PIP"
    Email   = var.owner_email
    Name    = "${var.name_prefix}-ec2-instance-profile"
  }
}

module "ap_south_1" {
  source = "./modules/ec2_benchmark"

  providers = {
    aws = aws.ap_south_1
  }

  region                = "ap-south-1"
  instance_profile_name = aws_iam_instance_profile.benchmark.name
  instances             = var.instances_by_region["ap-south-1"]
  project_tag            = var.project_tag
  owner_email            = var.owner_email
  environment            = var.environment
}

module "us_east_1" {
  source = "./modules/ec2_benchmark"

  providers = {
    aws = aws.us_east_1
  }

  region                = "us-east-1"
  instance_profile_name = aws_iam_instance_profile.benchmark.name
  instances             = var.instances_by_region["us-east-1"]
  project_tag            = var.project_tag
  owner_email            = var.owner_email
  environment            = var.environment
}

module "eu_west_1" {
  source = "./modules/ec2_benchmark"

  providers = {
    aws = aws.eu_west_1
  }

  region                = "eu-west-1"
  instance_profile_name = aws_iam_instance_profile.benchmark.name
  instances             = var.instances_by_region["eu-west-1"]
  project_tag            = var.project_tag
  owner_email            = var.owner_email
  environment            = var.environment
}

module "ap_southeast_1" {
  source = "./modules/ec2_benchmark"

  providers = {
    aws = aws.ap_southeast_1
  }

  region                = "ap-southeast-1"
  instance_profile_name = aws_iam_instance_profile.benchmark.name
  instances             = var.instances_by_region["ap-southeast-1"]
  project_tag            = var.project_tag
  owner_email            = var.owner_email
  environment            = var.environment
}

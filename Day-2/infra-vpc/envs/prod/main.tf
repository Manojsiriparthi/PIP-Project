terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../module"
  name = var.name
  environment = var.environment
  region = var.region
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_s3_flow_logs = var.enable_s3_flow_logs
  enable_s3_endpoint = var.enable_s3_endpoint
  enable_sqs_sns_endpoints = var.enable_sqs_sns_endpoints
  public_ingress_cidrs = var.public_ingress_cidrs
}

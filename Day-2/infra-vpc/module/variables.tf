variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_data_subnet_cidrs" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_s3_flow_logs" {
  type    = bool
  default = true
}

variable "enable_s3_endpoint" {
  type    = bool
  default = true
}

variable "enable_sqs_sns_endpoints" {
  type    = bool
  default = true
}

variable "public_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

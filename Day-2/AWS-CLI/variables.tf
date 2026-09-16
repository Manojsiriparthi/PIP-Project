variable "environment" {
  description = "Deployment environment: dev, test, or prod."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "name_prefix" {
  description = "Prefix used for IAM resources."
  type        = string
  default     = "pip-day2"
}

variable "project_tag" {
  description = "Project tag value."
  type        = string
  default     = "PIP"
}

variable "owner_email" {
  description = "Owner email tag."
  type        = string
  default     = "siriparthi.manojkumar@gmail.com"
}

variable "cloudwatch_namespace" {
  description = "CloudWatch namespace allowed by the EC2 role."
  type        = string
  default     = "PIP/EC2Benchmark"
}

variable "instances_by_region" {
  description = "Exactly two EC2 instance definitions per region."
  type = map(map(object({
    instance_type = string
    architecture  = string
    name          = string
  })))

  validation {
    condition = alltrue([
      for region, instances in var.instances_by_region :
      length(instances) == 2
    ])
    error_message = "Each configured region must contain exactly two instances."
  }

  validation {
    condition = length(var.instances_by_region) == 4
    error_message = "Exactly four regions must be configured."
  }
}

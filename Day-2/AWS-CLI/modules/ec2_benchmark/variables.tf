variable "region" {
  description = "AWS region for this module."
  type        = string
}

variable "instance_profile_name" {
  description = "EC2 instance profile."
  type        = string
}

variable "project_tag" {
  description = "Project tag."
  type        = string
}

variable "owner_email" {
  description = "Owner email tag."
  type        = string
}

variable "environment" {
  description = "Environment tag."
  type        = string
}

variable "instances" {
  description = "Two benchmark instances for this region."
  type = map(object({
    instance_type = string
    architecture  = string
    name          = string
  }))

  validation {
    condition = alltrue([
      for _, item in var.instances :
      contains(["arm64", "x86_64"], item.architecture)
    ])
    error_message = "architecture must be arm64 or x86_64."
  }
}

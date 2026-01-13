variable "name" {
  description = "Name identifier for the region"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region identifier"
  type        = string
}

variable "email" {
  description = "Email distribution list for AWS Account creation"
  type        = string
}

variable "environment" {
  description = "Environment identifier for the region"
  type        = string

  validation {
    condition     = contains(["dev", "int", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, int, stage, prod."
  }
}

variable "tags" {
  description = "Tags to apply to AWS account"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Kerberos ID of the owner, if a dev account"
  type        = string
  default     = ""

  validation {
    condition     = (var.environment == "dev" && var.owner != "") || (var.environment != "dev" && var.owner == "")
    error_message = "Owner is required when environment is 'dev' and must be empty for other environments."
  }
}

variable "ou_id" {
  description = "OU to place the accounts in"
  type        = string
}

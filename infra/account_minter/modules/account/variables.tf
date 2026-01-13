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

variable "role" {
  description = "Role for the account"
  type        = string
  validation {
    condition     = contains(["regional-cluster", "management-cluster-0", "management-cluster-1", "disaster-recovery", "database", "log-management"], var.role)
    error_message = "Account role must be one of regional-cluster, management-cluster-0, management-cluster-1, disaster-recovery, database, or log-management"
  }
}

variable "ou_id" {
  description = "OU to place the accounts in"
  type        = string
}

variable "owner" {
  description = "Kerberos ID of the owner, if a dev account"
  type        = string
  default     = ""
}

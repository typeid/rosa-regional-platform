# =============================================================================
# Management Cluster Bootstrap Variables
# =============================================================================

# Required Variables
variable "cluster_name" {
  description = "Name of the management EKS cluster"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
}

variable "region" {
  description = "AWS region for the management cluster"
  type        = string
}

# Optional Overrides
variable "node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

# Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ROSA-Regional-Platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


# =============================================================================
# EKS Cluster Module Variables - Minimal Configuration
# =============================================================================

# Basic Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_type" {
  description = "Type of cluster: 'regional' or 'management'"
  type        = string
  validation {
    condition = contains(["regional", "management"], var.cluster_type)
    error_message = "Cluster type must be either 'regional' or 'management'."
  }
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

# ArgoCD Configuration
variable "argocd_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
  default     = "https://github.com/openshift-online/rosa-regional-platform"
}

variable "argocd_config_path" {
  description = "Path in the repository for cluster configuration"
  type        = string
  # Will be set based on cluster_type: regional-cluster/configuration or management-cluster/configuration
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "ROSA-Regional-Platform"
    ManagedBy = "Terraform"
  }
}
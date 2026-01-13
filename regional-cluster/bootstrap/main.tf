# =============================================================================
# ROSA Regional Platform - Regional Cluster Bootstrap
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # TODO: Configure backend for state storage
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "rosa-regional-platform/regional-cluster/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# =============================================================================
# Regional Cluster Deployment
# =============================================================================

module "cluster" {
  source = "../../terraform/modules/eks-cluster"

  # Cluster Type Configuration
  cluster_type       = "regional"
  argocd_config_path = "regional-cluster/configuration"

  # Basic Configuration
  cluster_name = var.cluster_name
  aws_profile  = var.aws_profile
  region       = var.region

  # Optional Overrides
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size

  # Tags
  tags = merge(var.common_tags, {
    ClusterType = "Regional"
    Region      = var.region
  })
}
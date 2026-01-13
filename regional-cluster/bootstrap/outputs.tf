# =============================================================================
# Regional Cluster Bootstrap Outputs
# =============================================================================

# Cluster Information
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint (private)"
  value       = module.cluster.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.cluster.cluster_version
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.cluster.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs in the default VPC"
  value       = module.cluster.subnet_ids
}

# ArgoCD Information
output "argocd_addon_status" {
  description = "Status of ArgoCD EKS addon"
  value       = module.cluster.argocd_addon_status
}
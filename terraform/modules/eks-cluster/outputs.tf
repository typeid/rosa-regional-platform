# =============================================================================
# EKS Cluster Module Outputs
# =============================================================================

# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.cluster.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.cluster.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# Security and IAM
output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_eks_cluster.cluster.role_arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group_role.arn
}

# VPC and Networking
output "vpc_id" {
  description = "ID of the default VPC where the cluster is deployed"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the default VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "subnet_ids" {
  description = "List of subnet IDs in the default VPC"
  value       = data.aws_subnets.default.ids
}

# Node Group Information
output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.main.status
}

# ArgoCD Information
output "argocd_addon_arn" {
  description = "ARN of the ArgoCD EKS addon"
  value       = aws_eks_addon.argocd.arn
}

output "argocd_addon_status" {
  description = "Status of the ArgoCD EKS addon"
  value       = aws_eks_addon.argocd.status
}


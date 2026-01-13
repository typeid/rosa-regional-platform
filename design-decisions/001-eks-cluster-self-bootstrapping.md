# EKS Cluster Self-Bootstrapping with Terraform and ArgoCD

***Scope***: ROSA-RP

**Date**: 2026-01-13

## Decision

We will implement a self-bootstrapping approach for both Regional and Management EKS clusters using Terraform modules that automatically provision infrastructure and configure ArgoCD to manage post-deployment configuration from this repository.

## Context

The ROSA Regional Platform architecture requires two types of EKS clusters (Regional and Management) to be provisioned across multiple AWS accounts and regions. Each cluster needs to bootstrap itself with the appropriate software components and configurations after initial infrastructure provisioning.

- **Problem Statement**: We need a consistent, repeatable method to provision EKS clusters and ensure they automatically configure themselves with the appropriate software stack without manual intervention.
- **Constraints**:
  - Clusters must have private API endpoints for security
  - Different AWS accounts require separate authentication profiles
  - ArgoCD must be available as a managed service to reduce operational overhead
  - Configuration must be declarative and version-controlled
- **Assumptions**:
  - AWS EKS managed ArgoCD addon is available in target regions
  - Teams have appropriate AWS CLI profiles configured for each account
  - This repository serves as the single source of truth for cluster configurations

## Alternatives Considered

1. **Manual Cluster Setup + Helm Installation**: Manually provision EKS clusters and install ArgoCD via Helm charts with manual configuration
2. **AWS CDK with Custom Constructs**: Use AWS CDK to create higher-level constructs that manage both infrastructure and application deployment
3. **Terraform + Separate ArgoCD Bootstrap Scripts**: Use Terraform for infrastructure only, then run separate scripts to install and configure ArgoCD

## Decision Rationale

* **Justification**: The chosen approach provides the optimal balance of automation, maintainability, and operational simplicity. By using EKS managed ArgoCD, we eliminate the complexity of managing ArgoCD lifecycle while ensuring clusters can self-configure.
* **Evidence**: EKS managed addons provide better integration, automatic updates, and reduced operational overhead compared to self-managed installations. Terraform modules enable code reuse across cluster types while maintaining flexibility.
* **Comparison**: Alternative 1 increases manual work and operational burden. Alternative 2 introduces additional complexity with CDK. Alternative 3 requires additional tooling and coordination between Terraform and bootstrap scripts.

## Consequences

### Positive

* **Standardized Provisioning**: Single reusable Terraform module works for both Regional and Management clusters
* **Self-Healing Configuration**: ArgoCD automatically applies and reconciles cluster configuration from Git
* **Reduced Operational Overhead**: Managed ArgoCD addon eliminates installation and maintenance complexity
* **Version-Controlled Infrastructure**: All cluster configuration is tracked in Git with proper audit trail
* **Rapid Deployment**: New clusters can be provisioned and configured with minimal manual intervention
* **Consistency**: All clusters follow the same bootstrap pattern regardless of type or region

### Negative

* **Vendor Lock-in**: Dependency on AWS EKS managed ArgoCD addon limits portability
* **Limited ArgoCD Customization**: Managed addon may have fewer configuration options compared to self-installed ArgoCD
* **Bootstrap Dependency**: Clusters require this repository to be accessible for initial configuration
* **State Management Complexity**: Terraform state must be managed securely across multiple AWS accounts
* **Private Cluster Access**: Troubleshooting requires VPC access or bastion hosts due to private API endpoints

## Cross-Cutting Concerns

### Reliability:

* **Scalability**: Terraform modules can be reused to provision clusters in any number of regions and accounts. ArgoCD configuration paths allow independent management of different cluster types.
* **Observability**: Terraform outputs provide cluster endpoints and identifiers. ArgoCD provides built-in monitoring of configuration drift and application health.
* **Resiliency**: EKS managed addons provide automatic updates and health management. GitOps ensures configuration can be restored from source control.

### Security:

* **Private API Endpoints**: All EKS clusters use private API servers accessible only within the VPC
* **IAM Least Privilege**: Terraform creates minimal required IAM roles for cluster and node group operations
* **Secrets Management**: ArgoCD addon configuration includes repository access without exposing credentials in Terraform state
* **Network Isolation**: Each cluster receives its own isolated VPC with controlled routing
* **Audit Trail**: All infrastructure and configuration changes are tracked through Git and Terraform state

### Performance:

* **Fast Provisioning**: Terraform modules minimize deployment time through parallel resource creation
* **Efficient Resource Usage**: Default instance types (t3.medium) provide good price-performance for initial deployments
* **Auto-scaling**: EKS node groups support automatic scaling based on workload demand

### Cost:

* **Resource Efficiency**: Shared VPC module and minimal default configurations reduce unnecessary costs
* **Managed Service Benefits**: EKS managed addons eliminate compute costs for self-hosted ArgoCD
* **Variable Instance Types**: Terraform variables allow cost optimization through different instance types per environment
* **Single NAT Gateway**: Default configuration uses one NAT gateway per cluster to minimize data transfer costs

### Operability:

* **Simple Deployment Pattern**: Copy tfvars.example, customize, and run terraform apply
* **Clear Separation of Concerns**: Infrastructure provisioning (Terraform) and application configuration (ArgoCD) are distinct phases
* **Troubleshooting**: Terraform outputs provide necessary information for cluster access and debugging
* **Configuration Drift Detection**: ArgoCD automatically detects and reports configuration differences
* **Rollback Capability**: Git-based configuration allows easy rollback to previous known-good states
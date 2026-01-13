# ROSA Regional Platform

Infrastructure and configuration for the ROSA (Red Hat OpenShift Service on AWS) Regional Platform.

## Repository Structure

```
rosa-regional-platform/
├── regional-cluster/
│   ├── bootstrap/              # Terraform for Regional Cluster
│   └── configuration/          # ArgoCD manages this directory
├── management-cluster/
│   ├── bootstrap/              # Terraform for Management Cluster
│   └── configuration/          # ArgoCD manages this directory
├── terraform/modules/eks-cluster/ # Shared Terraform module
└── design-decisions/           # Architecture documentation
```

## Documentation

- [Design Decisions](design-decisions/) - Architecture choices and rationale
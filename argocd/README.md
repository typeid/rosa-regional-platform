# ROSA Regional Platform - ArgoCD Configuration

This directory contains the ArgoCD configuration structure for the ROSA Regional Platform, implementing a shard-based approach where each region operates independently with its own ArgoCD instances.

## Architecture Overview

The ArgoCD deployment follows an **ApplicationSet-driven pattern** where a single root ApplicationSet dynamically discovers and manages all cluster applications based on cluster secrets.

```
argocd/
├── applicationset/
│   └── root-applicationset.yaml   # 🎯 Main ApplicationSet (Root reference for MC/RC ArgoCD)
├── config/
│   ├── shared/                    # 📦 Helm charts shared between MCs and RCs 
│   ├── managementcluster/         # 📦 Helm charts specific to MCs
│   └── regionalcluster/           # 📦 Helm charts specific to RCs
├── config.yaml                    # ⚙️ Shard registry and default values overrides
├── scripts/render.py              # 🔄 Generates region-specific value overrides
└── rendered/                      # 📁 Value outputs generated from rendering (DO NOT EDIT)
    └── {environment}/{sector}/{region}/
        ├── managementcluster-values.yaml
        └── regionalcluster-values.yaml
```

## Architecture Flow

```
┌─────────────────┐
│  ECS Bootstrap  │
│      Task       │
└─────────┬───────┘
          │
          ├─── Creates Root Application (unmanaged)
          │    └── Points to: argocd/applicationset/root-applicationset.yaml
          │
          └─── Creates Cluster Secrets
               └── Labels: cluster_type={management|regional}, region
                   Annotations: git_repo, git_revision

                               ┌─────────────────────────┐
                               │   Root ApplicationSet   │
                               │  (Matrix Generator)     │
                               └────────┬────────────────┘
                                        │
                        ┌───────────────┴───────────────┐
                        │                               │
                   ┌────▼────┐                    ┌─────▼─────┐
                   │   Git   │                    │  Cluster  │
                   │Generator│◄──────────────────►│ Generator │
                   └────┬────┘                    └─────┬─────┘
                        │                               │
                        │ Scans:                        │ Uses cluster secret to
                        │ - config/shared/*             │ template paths:
                        │ - config/managementcluster/*  │ {{metadata.labels.cluster_type}}
                        │ - config/regionalcluster/*    │
                        │                               │
                        └───────────┬───────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │   Generated Apps      │
                        │   (Example)           │
                        │                       │
                        │ • argocd (MC + RC)    │
                        │ • hypershift (MC only)│
                        └───────────────────────┘

Each app uses:
- Chart from: argocd/config/{cluster_type}/{chart}/
- Values from: argocd/rendered/{env}/{sector}/{region}/{cluster_type}-values.yaml
```

## How It Works

### 1. ApplicationSet Pattern

The **Root ApplicationSet** uses a **Matrix Generator** combining:
- **Git Generator**: Scans `argocd/config/{cluster_type}cluster/*` and `argocd/config/shared/*` for Helm charts
- **Cluster Generator**: Discovers clusters via Kubernetes secrets with label `argocd.argoproj.io/secret-type: cluster`

For each `(cluster, chart)` pair, the ApplicationSet creates an **Application** that:
```yaml
# Generated Application example
metadata:
  name: argocd  # From chart directory name
  labels:
    cluster_type: managementcluster
    environment: integration
    region: eu-west-1
spec:
  sources:
    - helm:
        valueFiles:
          - values.yaml  # Chart defaults
          - $values/argocd/rendered/integration/dev/eu-west-1/managementcluster-values.yaml  # Overrides
      path: argocd/config/managementcluster/hypershift
```

### 2. Configuration System

**Default Values**: Stored in Helm chart `values.yaml` files
```bash
argocd/config/shared/argocd/values.yaml                    # ArgoCD defaults (all clusters)
argocd/config/managementcluster/hypershift/values.yaml     # HyperShift defaults
```

**Shard Overrides**: Defined in the registry file
```bash
argocd/config.yaml                                         # All shard configurations
```

### 3. Render Process

The render script processes configuration in this order:
1. **Shard Discovery**: Reads `config.yaml` to find all shards (regions)
2. **Cluster Type Discovery**: Scans `argocd/config/` for cluster type directories
3. **Override Generation**: For each shard + cluster type, generates override files with **only the differences**
4. **Output**: Override-only files in `rendered/{environment}/{sector}/{region}/` directory

```bash
# Generate all region-specific value overrides
argocd/scripts/render.py
```

**Key Principle**: Rendered files contain **only overrides**, not defaults. Helm defaults stay in chart `values.yaml` files.


## Configuration Workflow

### To Add a New Region

1. **Add shard to config.yaml**:
```yaml
shards:
  - region: "ap-southeast-1"
    environment: "production"
    sector: "prod"
    values:
      managementcluster:
        hypershift:
          oidcStorageS3Bucket:
            name: "hypershift-mc-ap-southeast-1"
            region: "ap-southeast-1"
```

2. **Run render script**:
```bash
argocd/scripts/render.py
```

3. **Bootstrap clusters**: ECS bootstrap task creates cluster secrets and applications
4. **Auto-discovery**: ApplicationSet automatically creates applications for the new region

## Known Limitations & Future Work

### 🚨 Template Versioning Problem
**Issue**: We can currently only modify Helm values per region, but not the actual Helm templates. This creates problems when:
- CRDs change between chart versions
- Incompatible template changes occur
- We need gradual rollouts across regions

**Current Limitation**: All regions must use the same Helm templates/CRDs
**Proposed Solution**: Support different template versions per region/shard

### 🔍 Shard Visibility Problem
**Issue**: The ApplicationSet abstraction makes it difficult to directly see what's deployed in each shard without understanding the generator matrix.

**Current Limitation**: Must mentally combine cluster labels + git paths to understand actual deployments
**Consideration**: Whether to maintain ApplicationSet flexibility vs. direct shard visibility

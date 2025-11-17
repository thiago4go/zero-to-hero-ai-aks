# Implementation Plan: Baseline Deployment (Module 0)

**Branch**: `000-baseline-deployment` | **Date**: 2025-11-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/000-baseline-deployment/spec.md`

## Summary

Deploy the complete dapr-store application to Azure Kubernetes Service (AKS) as the foundation for AI enhancements. This includes migrating the products service from SQLite to Azure Database for PostgreSQL for horizontal scalability, deploying the Prometheus/Grafana monitoring stack for observability, and implementing lab cost management scripts to stop/start resources when not in use.

**Primary Requirement**: Fully functional dapr-store on AKS with PostgreSQL backend, monitoring, and cost controls.

**Technical Approach**: Use Bicep/Terraform for infrastructure provisioning, Helm for application deployment, modify products service to use Dapr PostgreSQL state store, deploy kube-prometheus-stack, and create bash scripts for lab lifecycle management (start/stop/cleanup).

## Technical Context

**Language/Version**: 
- Infrastructure: Bicep or Terraform
- Products Service: Go 1.23+ (existing)
- Scripts: Bash

**Primary Dependencies**: 
- Azure CLI 2.47.0+
- kubectl 1.28+
- Helm 3.12+
- Dapr CLI 1.12+
- Azure Bicep CLI (if using Bicep)

**Storage**: 
- Azure Database for PostgreSQL Flexible Server (Burstable B1ms, 32GB)
- Azure Blob Storage (optional, for Terraform state)

**Testing**: 
- Manual verification via kubectl and browser
- Automated health checks via Kubernetes probes
- Cost verification via Azure Cost Management

**Target Platform**: Azure Kubernetes Service (AKS) on Linux

**Project Type**: Infrastructure + application deployment (Module 0 baseline)

**Performance Goals**: 
- Deployment completes in <30 minutes
- Application accessible within 5 minutes of Helm install
- Stop/start operations complete within 5-10 minutes

**Constraints**: 
- Must support AKS stop/start (no classic load balancer)
- PostgreSQL must be Flexible Server (supports stop)
- Total cost <$10 for 3-hour session with stop/start
- All resources must be tagged for cost tracking

**Scale/Scope**: 
- 2-3 AKS worker nodes (Standard_D2s_v3)
- 5 microservices + frontend + gateway
- ~100 products in catalog
- Single region deployment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Microservices-First Architecture
- ✅ **PASS**: Deploys existing dapr-store microservices (products, users, cart, orders)
- ✅ **PASS**: All services Dapr-enabled with service invocation
- ✅ **PASS**: Containerized with health checks

### Principle II: AKS-Native Deployment
- ✅ **PASS**: Deploys to AKS with Helm charts
- ✅ **PASS**: Resource requests/limits configured
- ✅ **PASS**: Integrates with Azure services (PostgreSQL, Monitor)

### Principle III: AI Model Integration Standards
- ⚠️ **N/A**: Module 0 is baseline - no AI features yet
- ✅ **PASS**: Prepares infrastructure for Level 1-4 AI progression

### Principle IV: Observability & Monitoring
- ✅ **PASS**: Deploys Prometheus/Grafana stack
- ✅ **PASS**: Services expose /metrics endpoints
- ✅ **PASS**: ServiceMonitor CRDs for Dapr metrics
- ✅ **PASS**: Pre-configured Grafana dashboards

### Principle V: Incremental AI Enhancement
- ✅ **PASS**: Establishes working baseline for AI enhancements
- ✅ **PASS**: No AI features in Module 0 (incremental approach)

### Principle VI: Data Persistence & Scalability (NON-NEGOTIABLE)
- ✅ **PASS**: Migrates products service from SQLite to PostgreSQL
- ✅ **PASS**: Uses Dapr PostgreSQL state store
- ✅ **PASS**: Enables horizontal scaling of products service

### Security Standards
- ✅ **PASS**: PostgreSQL with encryption at rest
- ✅ **PASS**: TLS for all connections
- ✅ **PASS**: Network policies (optional for Module 0, required for production)

### Cost Optimization
- ✅ **PASS**: AKS supports stop/start
- ✅ **PASS**: PostgreSQL Flexible Server supports stop
- ✅ **PASS**: Budget alerts configured
- ✅ **PASS**: lab-start.sh, lab-stop.sh, lab-cleanup.sh scripts provided

### Lab Lifecycle Management
- ✅ **PASS**: Stop/start instructions included
- ✅ **PASS**: Cleanup instructions included
- ✅ **PASS**: Cost estimate provided (<$10 for 3 hours)

**Overall Status**: ✅ **PASSED** - All gates passed. Module 0 establishes compliant baseline for AI lab.

## Project Structure

### Documentation (this feature)

```text
specs/000-baseline-deployment/
├── plan.md              # This file
├── research.md          # Phase 0 - Infrastructure decisions
├── data-model.md        # Phase 1 - PostgreSQL schema
├── quickstart.md        # Phase 1 - Deployment guide
├── contracts/           # Phase 1 - N/A (infrastructure)
└── tasks.md             # Phase 2 - NOT created yet
```

### Source Code (repository root)

**Structure Decision**: Infrastructure as Code + application modifications

```text
/
├── infrastructure/                  # NEW: IaC for Azure resources
│   ├── bicep/                      # NEW: Bicep templates
│   │   ├── main.bicep              # NEW: Main deployment
│   │   ├── aks.bicep               # NEW: AKS cluster
│   │   ├── postgresql.bicep        # NEW: PostgreSQL server
│   │   ├── monitoring.bicep        # NEW: Log Analytics
│   │   └── parameters.json         # NEW: Deployment parameters
│   └── terraform/                  # ALTERNATIVE: Terraform (if preferred)
│       ├── main.tf
│       ├── aks.tf
│       ├── postgresql.tf
│       └── variables.tf
├── scripts/                        # NEW: Lab lifecycle scripts
│   ├── lab-start.sh                # NEW: Start AKS + PostgreSQL
│   ├── lab-stop.sh                 # NEW: Stop AKS + PostgreSQL
│   ├── lab-cleanup.sh              # NEW: Delete all resources
│   └── setup-budget-alerts.sh      # NEW: Configure cost alerts
├── dapr-store/
│   ├── cmd/
│   │   └── products/
│   │       ├── impl/
│   │       │   └── impl.go         # MODIFIED: Use Dapr PostgreSQL state store
│   │       └── main.go             # MODIFIED: Load products.csv to PostgreSQL
│   ├── components/
│   │   └── statestore-postgres.yaml # NEW: Dapr PostgreSQL component
│   └── deploy/
│       └── helm/
│           └── daprstore/
│               ├── values.yaml     # MODIFIED: PostgreSQL connection
│               └── templates/
│                   └── products.yaml # MODIFIED: Dapr annotations
├── monitoring/                     # NEW: Monitoring configs
│   ├── prometheus-values.yaml      # NEW: Prometheus config
│   ├── grafana-dashboards/         # NEW: Pre-configured dashboards
│   │   ├── dapr-store-overview.json
│   │   └── service-health.json
│   └── servicemonitor.yaml         # NEW: Dapr metrics scraping
└── docs/
    └── module-0-baseline.md        # NEW: Module 0 documentation
```

**Key Changes**:
- **New directory**: `infrastructure/` - Bicep or Terraform for Azure resources
- **New directory**: `scripts/` - Lab lifecycle management
- **New directory**: `monitoring/` - Prometheus/Grafana configs
- **Modified**: `dapr-store/cmd/products/` - PostgreSQL integration
- **New component**: `statestore-postgres.yaml` - Dapr PostgreSQL config

## Complexity Tracking

> **No violations** - All constitution checks passed. No complexity justification needed.

---

## Phase 0: Research (To be completed)

Research tasks:
1. **Bicep vs Terraform**: Choose IaC tool for Azure deployment
2. **AKS Configuration**: Node size, Dapr extension setup, stop/start requirements
3. **PostgreSQL Configuration**: Flexible Server tier, connection pooling, Dapr integration
4. **Products Service Migration**: SQLite to PostgreSQL data migration strategy
5. **Monitoring Stack**: kube-prometheus-stack configuration, dashboard design
6. **Cost Management**: Budget alert setup, stop/start automation

## Phase 1: Design (To be completed)

Design artifacts:
1. **data-model.md**: PostgreSQL schema for products
2. **quickstart.md**: Step-by-step deployment guide
3. **contracts/**: N/A for infrastructure module

## Next Steps

Run `/speckit.plan` to complete Phase 0 research and Phase 1 design, then `/speckit.tasks` to break down into implementation tasks.

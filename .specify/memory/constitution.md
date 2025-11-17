<!--
SYNC IMPACT REPORT
==================
Version Change: 1.2.0 → 1.3.0
Change Type: MINOR - Added explicit lab cost management and stop/start procedures
Modified Sections:
  - Cost Optimization: Added stop/start requirements, daily workflow, cost estimates
  - Lab Exercise Requirements: Added stop/start and cleanup instructions (items 7-8)
  - Lab Lifecycle Management: NEW section with pre-lab setup, daily session, cleanup, emergency controls
Rationale:
  - Lab environment requires explicit cost control (not production)
  - AKS and PostgreSQL MUST be stoppable to avoid idle costs
  - Estimated costs: $40-70 with stop/start vs $200-300 if left running
  - Budget alerts and emergency procedures prevent cost overruns

Templates Status:
✅ plan-template.md - Compatible (cost estimates already required)
✅ spec-template.md - Compatible (no changes needed)
✅ tasks-template.md - Compatible (cleanup tasks can be added)

Follow-up TODOs: 
  - Create lab-start.sh, lab-stop.sh, lab-cleanup.sh scripts
  - Add stop/start instructions to quickstart.md templates
  - Document budget alert setup in Module 0
  - Create cost monitoring dashboard template
-->

# AI on AKS Lab Constitution

## Core Principles

### I. Microservices-First Architecture
Every AI capability MUST be deployed as an independent microservice following the existing Dapr Store pattern. Services MUST be:
- Self-contained with clear boundaries
- Independently deployable and scalable
- Dapr-enabled for service invocation, state, and pub/sub
- Containerized with health checks and observability

**Rationale**: Maintains consistency with baseline dapr-store architecture, enables independent scaling of AI workloads, and leverages Dapr's distributed application patterns.

### II. AKS-Native Deployment
All services MUST be Kubernetes-native and optimized for Azure Kubernetes Service (AKS). This requires:
- Helm charts for all deployments
- Proper resource requests/limits for CPU and memory
- Horizontal Pod Autoscaling (HPA) configuration
- Integration with Azure services (Container Registry, Key Vault, Monitor)

**Rationale**: Ensures production-ready deployments on AKS with proper resource management and Azure cloud integration.

### III. AI Model Integration Standards
AI/ML models MUST follow the four-level progression framework:

**Level 1 - Gen AI via API**: Direct Azure OpenAI/AI Services integration
- REST API calls with Managed Identity (NO API keys in code)
- Response caching for cost optimization
- Graceful fallback for service unavailability

**Level 2 - Open Source Models**: KAITO-deployed models on AKS
- Models served via KAITO Workspace CRDs
- GPU node pools with autoscaling (min-count=0 for cost)
- vLLM optimization: FP8 quantization, avoid tensor parallelism for <13B models
- Pre-cache models in Azure Container Registry

**Level 3 - Custom Models**: Azure ML trained models
- MLflow tracking for all experiments
- Models registered in Azure ML Model Registry
- Training data from Dapr state stores or Azure PostgreSQL
- Automated retraining pipelines via GitHub Actions

**Level 4 - Full MLOps**: Production deployment with monitoring
- Models deployed to AKS via Azure ML endpoints
- Integrated into Dapr pub/sub event flows
- Prometheus metrics for model performance
- GitOps-based deployment (Flux or ArgoCD)

**Rationale**: Progressive complexity enables incremental learning while maintaining production-grade patterns at each level.

### IV. Observability & Monitoring
All services MUST implement comprehensive observability using the Prometheus/Grafana stack:

**Application Metrics**:
- Prometheus `/metrics` endpoint on all services
- Standard metrics: request latency, error rates, throughput
- Custom metrics: AI model inference time, confidence scores, cache hit rates

**AI Model Monitoring**:
- Model drift detection (Evidently AI or custom)
- Inference latency histograms
- Prediction distribution tracking
- A/B test result metrics

**Infrastructure**:
- Dapr metrics via ServiceMonitor CRDs
- GPU utilization tracking (DCGM exporter)
- Azure Monitor integration for AKS cluster insights
- Distributed tracing via Dapr/OpenTelemetry

**Dashboards**:
- Grafana dashboards for each service
- MLOps dashboard: training runs, model versions, deployment status
- Cost dashboard: GPU hours, API call costs, storage usage

**Rationale**: AI systems require specialized monitoring for model performance, drift, and cost management beyond standard application metrics.

### V. Incremental AI Enhancement
AI features MUST be added incrementally without breaking existing functionality:
- Baseline dapr-store features remain operational
- AI services are optional enhancements (graceful degradation)
- Feature flags control AI feature rollout
- Each AI capability independently testable

**Rationale**: Maintains working baseline for lab exercises, allows progressive learning, and reduces risk of system-wide failures.

### VI. Data Persistence & Scalability (NON-NEGOTIABLE)
The products service SQLite bottleneck MUST be resolved before AI integration:

**Required Migration**: SQLite → Azure Database for PostgreSQL Flexible Server
- Use Dapr PostgreSQL state store component (`state.postgresql`)
- Connection strings via Kubernetes Secrets or Azure Key Vault
- Dual-write pattern during migration for zero downtime
- Products data loaded from `data/products.csv` on initialization

**Rationale**: SQLite file-based storage breaks horizontal scaling. Each pod replica gets its own database copy, causing data inconsistency. PostgreSQL enables true microservices scalability required for production AI workloads.

**Alternative**: For local development only, Redis with RediSearch can substitute for PostgreSQL.

## Technology Standards

### Required Stack
- **Container Runtime**: Docker/containerd on AKS
- **Orchestration**: Kubernetes 1.28+ on Azure AKS
- **Service Mesh**: Dapr 1.12+ for microservices patterns
- **Backend Services**: Go 1.23+ (existing), Python 3.11+ (AI services with FastAPI)
- **AI/ML Frameworks**: 
  - PyTorch, TensorFlow, scikit-learn for custom models
  - Azure OpenAI SDK for Level 1 integrations
  - KAITO for Level 2 open-source model deployment
  - MLflow for experiment tracking and model registry
  - MCP (Model Context Protocol) for Level 4 chatbot tool integration
- **Frontend**: Vue.js 3+ (existing), enhanced with AI features
- **State Store**: 
  - **Production**: Azure Database for PostgreSQL Flexible Server (via Dapr)
  - **Development**: Redis Stack with RediSearch
- **Messaging**: Azure Service Bus or Redis (via Dapr pub/sub)
- **Monitoring**: 
  - Prometheus + Grafana (kube-prometheus-stack Helm chart)
  - Azure Monitor for AKS cluster-level insights
  - Evidently AI for model drift detection

### Azure Services Integration
- **Azure Container Registry (ACR)**: Container image storage, KAITO model caching
- **Azure Key Vault**: Secrets management via Dapr secret store
- **Azure OpenAI Service**: Level 1 AI capabilities (product descriptions, chatbot)
- **Azure Machine Learning**: Level 3-4 model training, registry, and deployment
- **Azure Database for PostgreSQL**: Scalable state store for products service
- **Azure Monitor**: Centralized logging, metrics, and Application Insights

### GPU Configuration
- **Node Pool**: Standard_NC24ads_A100_v4 or equivalent
- **Autoscaling**: min-count=0, max-count=3 (scale to zero for cost)
- **Taints**: `sku=gpu:NoSchedule` to prevent non-GPU workloads
- **KAITO**: Pre-installed on cluster for Level 2 model deployment

## Security Standards

### Authentication & Authorization
- **Managed Identity**: ALL Azure service connections MUST use Managed Identity
- **NO API Keys**: API keys in code, environment variables, or ConfigMaps are PROHIBITED
- **Secrets Management**: Use Azure Key Vault via Dapr secret store component
- **RBAC**: Assign minimum required roles (e.g., "Cognitive Services OpenAI User")

### Network Security
- **Private Endpoints**: Azure services accessed via private endpoints where possible
- **Network Policies**: Kubernetes NetworkPolicies to restrict pod-to-pod traffic
- **Ingress**: NGINX ingress with TLS termination
- **Dapr mTLS**: Enabled for all service-to-service communication

### Data Protection
- **Encryption at Rest**: Azure PostgreSQL with encryption enabled
- **Encryption in Transit**: TLS 1.2+ for all external connections
- **PII Handling**: No customer PII in logs or metrics
- **Model Data**: Training data anonymized before Azure ML ingestion

## Development Workflow

### Lab Module Structure
Each AI enhancement follows the four-level progression as independent lab modules:

**Module 0: Baseline Deployment** (30 minutes)
- Deploy dapr-store to AKS with Helm
- Migrate products service from SQLite to PostgreSQL
- Install Prometheus/Grafana monitoring stack
- Verify baseline functionality

**Module 1: Level 1 - Gen AI via API** (45 minutes)
- Integrate Azure OpenAI for AI-generated product descriptions
- Implement Managed Identity authentication
- Add response caching for cost optimization
- Monitor API usage and costs

**Module 2: Level 2 - Open Source Models** (90 minutes)
- Deploy KAITO with sentence-transformer model
- Create recommendation service using collaborative filtering
- Integrate recommendations into product detail pages
- Monitor GPU utilization and inference latency

**Module 3: Level 3 - Custom Model Training** (120 minutes)
- Extract product data from PostgreSQL (name, description, existing categories)
- Train multi-class classification model in Azure ML with MLflow tracking
- Register category prediction model in Azure ML Model Registry
- Evaluate model accuracy, precision, recall metrics
- Test predictions on uncategorized products

**Module 4: Level 4 - Full MLOps** (90 minutes)
- Deploy custom chatbot service with Azure OpenAI function calling
- Implement MCP server with tools: search_products, get_order_status, get_user_profile, add_to_cart
- Integrate conversation memory via Dapr state store
- Connect chatbot to all services via Dapr service invocation
- Implement automated model update pipeline (GitHub Actions)
- Configure GitOps deployment with Flux/ArgoCD
- Add Prometheus metrics for conversation quality and tool usage

**Total Lab Time**: ~6 hours (full-day workshop)

### Lab Exercise Requirements
Each module MUST include:
1. **Objective**: Clear learning goal and AI capability being added
2. **Prerequisites**: Required baseline state, Azure resources, quotas
3. **Implementation Steps**: Incremental tasks with validation checkpoints
4. **Testing**: Independent verification of AI feature functionality
5. **Rollback**: Ability to revert to previous working state
6. **Cost Estimate**: Expected Azure costs for module completion
7. **Stop/Start Instructions**: Commands to stop resources after module completion
8. **Cleanup Instructions**: Commands to delete resources if module not needed

### Lab Lifecycle Management

#### Pre-Lab Setup (One-Time)
```bash
# Set budget alerts
az consumption budget create \
  --budget-name "ai-aks-lab-budget" \
  --amount 150 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date -d "+1 month" +%Y-%m-01)

# Tag all resources
az tag create --resource-id $RESOURCE_ID --tags lab=ai-aks environment=learning
```

#### Daily Lab Session
```bash
# START: Begin lab session (~5 min startup)
./scripts/lab-start.sh

# WORK: Complete lab modules

# STOP: End lab session (MANDATORY - saves $$)
./scripts/lab-stop.sh
```

#### Post-Lab Cleanup (After Lab Completion)
```bash
# Delete all lab resources
./scripts/lab-cleanup.sh

# Verify deletion
az resource list --tag lab=ai-aks
```

#### Emergency Cost Control
If costs exceed budget:
1. Immediately stop AKS: `az aks stop --name $AKS_CLUSTER --resource-group $RG`
2. Stop PostgreSQL: `az postgres flexible-server stop --name $POSTGRES_SERVER --resource-group $RG`
3. Delete GPU node pool: `az aks nodepool delete --name gpunp --cluster-name $AKS_CLUSTER --resource-group $RG`
4. Review Azure Cost Management for unexpected charges

### Code Organization
```
/
├── dapr-store/              # Baseline microservices (preserved)
│   ├── cmd/                 # Go services (products, users, cart, orders)
│   ├── web/frontend/        # Vue.js SPA
│   └── deploy/helm/         # Kubernetes Helm charts
├── ai-services/             # New AI microservices
│   ├── recommendations/     # Level 2: Product recommendation service
│   │   ├── Dockerfile
│   │   ├── main.py          # FastAPI service
│   │   ├── model.py         # Collaborative filtering logic
│   │   └── requirements.txt
│   ├── chatbot/             # Level 4: Conversational AI service
│   │   ├── Dockerfile
│   │   ├── main.py          # FastAPI service with Azure OpenAI
│   │   ├── mcp_server.py    # MCP server implementation
│   │   ├── tools/           # MCP tool definitions
│   │   │   ├── products.py  # search_products, get_product
│   │   │   ├── orders.py    # get_order_status, list_orders
│   │   │   ├── users.py     # get_user_profile
│   │   │   └── cart.py      # add_to_cart, get_cart
│   │   ├── memory.py        # Conversation state management
│   │   └── requirements.txt
│   └── shared/              # Common utilities (Dapr client, metrics)
├── ml/                      # Machine learning pipelines
│   ├── training/            # Azure ML training scripts
│   │   ├── category-model/  # Level 3: Product categorization training
│   │   └── recommendation/  # Future: Recommendation model training
│   └── notebooks/           # Exploratory data analysis
├── deploy/
│   ├── helm/                # Extended Helm charts for AI services
│   ├── aks/                 # AKS-specific configs (GPU node pools)
│   ├── kaito/               # KAITO Workspace manifests
│   └── monitoring/          # Prometheus/Grafana configs
├── .github/workflows/       # CI/CD pipelines
│   ├── ci-build.yml         # Existing CI (extended)
│   ├── mlops-train.yml      # Azure ML training trigger
│   └── gitops-deploy.yml    # Flux/ArgoCD sync
└── .specify/                # Project governance (this file)
```

### Testing Requirements
- **Unit Tests**: AI model inference logic, data preprocessing
- **Integration Tests**: Service-to-service communication via Dapr
- **Contract Tests**: API endpoint validation (OpenAPI specs)
- **Load Tests**: AI service performance under concurrent requests
- **Model Tests**: 
  - Accuracy, precision, recall for classification models
  - Latency benchmarks (p50, p95, p99)
  - Model drift detection (reference vs. current data)
- **End-to-End Tests**: Complete user journeys with AI features enabled

### CI/CD Pipeline Requirements
- **Continuous Integration**: GitHub Actions for build, test, container push
- **Continuous Deployment**: GitOps with Flux or ArgoCD for AKS deployment
- **MLOps Automation**:
  - Trigger Azure ML training on main branch merge
  - Automated model registration after successful training
  - Canary deployment for new model versions
- **Infrastructure as Code**: Terraform or Bicep for Azure resource provisioning

### Cost Optimization

**CRITICAL FOR LAB**: This is a learning environment. All resources MUST support stop/start to avoid costs when not in use.

#### Stop/Start Requirements
- **AKS Cluster**: MUST be stoppable when lab not in use
  - Use `az aks stop` and `az aks start` commands
  - Stopped cluster incurs NO compute costs (only storage)
  - Start time: ~5 minutes
- **Azure OpenAI**: Pay-per-use (no idle costs, but monitor usage)
- **Azure Database for PostgreSQL**: Use Flexible Server with stop capability
  - Can be stopped for up to 7 days
  - Automatically starts after 7 days
- **GPU Node Pools**: Scale to zero when idle (min-count=0)
  - Autoscaler removes nodes when no workloads
  - Manual scale: `kubectl scale deployment --replicas=0`
- **Azure ML Compute**: Stop compute instances when not training
  - Use compute instances (not clusters) for training
  - Stop via Azure Portal or CLI

#### Daily Lab Workflow
```bash
# Start of lab session
az aks start --name $AKS_CLUSTER --resource-group $RG
az postgres flexible-server start --name $POSTGRES_SERVER --resource-group $RG

# End of lab session (ALWAYS RUN THIS)
az aks stop --name $AKS_CLUSTER --resource-group $RG
az postgres flexible-server stop --name $POSTGRES_SERVER --resource-group $RG
```

#### Cost Monitoring
- **Budget Alerts**: Set Azure budget alerts at $50, $100, $150
- **Daily Cost Review**: Check Azure Cost Management daily during lab
- **Resource Tagging**: Tag all resources with `lab=ai-aks` for cost tracking
- **Cleanup Script**: Provide script to delete all resources after lab completion

#### Cost Optimization Strategies
- **GPU Autoscaling**: Scale to zero when idle (min-count=0)
- **Spot Instances**: Use for non-critical training workloads (70% cost savings)
- **API Caching**: Cache Azure OpenAI responses for repeated queries (80%+ hit rate target)
- **Model Optimization**: FP8 quantization for inference, avoid tensor parallelism for <13B models
- **Storage Tiering**:
  - Hot: Redis (cache, session state) - minimal cost
  - Warm: PostgreSQL (products, orders, users) - stoppable
  - Cold: Azure Blob Storage (model artifacts, training data, logs) - archive tier for old data
- **Right-Sizing**: Use smallest VM sizes that meet performance requirements
  - AKS: Standard_D2s_v3 for worker nodes (not D4s or larger)
  - GPU: Standard_NC24ads_A100_v4 only when needed (scale to zero otherwise)
  - PostgreSQL: Burstable B1ms tier for lab (not General Purpose)

#### Estimated Lab Costs (Per Module)
- **Module 0** (Baseline): ~$5-10 (AKS + PostgreSQL, 2-3 hours)
- **Module 1** (Azure OpenAI): ~$2-5 (API calls, 1 hour)
- **Module 2** (KAITO): ~$15-25 (GPU node, 2 hours)
- **Module 3** (Training): ~$10-20 (Azure ML compute, 2 hours)
- **Module 4** (MLOps): ~$5-10 (deployment, 2 hours)
- **Total Lab**: ~$40-70 if resources stopped between sessions
- **Total Lab (no stop)**: ~$200-300 if resources left running 24/7

**MANDATE**: Include stop/start instructions in every module's quickstart.md

## Governance

### Constitution Authority
This constitution supersedes all other development practices. Any deviation MUST be:
1. Documented with clear justification
2. Reviewed for impact on lab learning objectives
3. Approved before implementation
4. Tracked in complexity tracking tables (per plan-template.md)

### Amendment Process
- **MINOR version bump**: Adding new AI service types or deployment patterns
- **PATCH version bump**: Clarifications, tooling updates, non-breaking refinements
- **MAJOR version bump**: Fundamental architecture changes (requires full lab review)

### Compliance Verification
- All feature specifications MUST pass constitution check (per plan-template.md)
- Pull requests MUST reference applicable principles
- Lab exercises MUST validate against core principles
- Quarterly review of AI service patterns and standards

### Lab-Specific Guidance
For runtime development guidance during lab exercises, refer to:
- `dapr-store/README.md` - Baseline application guide
- `deploy/aks/README.md` - AKS deployment procedures
- `ai-services/README.md` - AI service development patterns

**Version**: 1.3.0 | **Ratified**: 2025-11-16 | **Last Amended**: 2025-11-16

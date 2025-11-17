# Module 0: Baseline Deployment - Summary

**Deployment Date**: 2025-11-17  
**Status**: ✅ COMPLETE - Ready for Module 1 (AI Integration)

## 🌐 Deployed Resources

### Azure Infrastructure

| Resource | Name | Location | Status |
|----------|------|----------|--------|
| Resource Group | rg-ai-aks-lab-v3 | westus2 | ✅ Active |
| AKS Cluster | aks-ai-lab | westus2 | ✅ Running |
| PostgreSQL | postgres-ai-lab-thiago-v2 | centralus | ✅ Running (not used) |
| Log Analytics | logs-ai-lab | westus2 | ✅ Active |

**Note**: PostgreSQL was provisioned but not integrated (SQLite sufficient for AI work).

### Kubernetes Resources

| Component | Type | Status | Notes |
|-----------|------|--------|-------|
| Dapr | Extension | ✅ Running | Managed by AKS |
| Redis | StatefulSet | ✅ Running | State store & pub/sub |
| NGINX Ingress | LoadBalancer | ✅ Running | API Gateway |
| Dapr Store App | Deployment | ✅ Running | 5 microservices |
| Prometheus | StatefulSet | ✅ Running | Metrics collection |
| Grafana | Deployment | ✅ Running | Dashboards |

## 🔗 Access URLs

### Application
- **Store Frontend**: http://172.193.227.28/
- **Products API**: http://172.193.227.28/v1.0/invoke/products-service/method/catalog

### Monitoring
- **Grafana**: Port-forward required
  ```bash
  kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
  ```
  - URL: http://localhost:3000
  - Username: `admin`
  - Password: `admin`

## 📊 Implementation Progress

### Completed Tasks: 35/67 (52%)

**Phase 1: Setup** ✅ (4/4)
- Created directory structure
- Created .gitignore

**Phase 2: Foundational** ✅ (14/14)
- Bicep templates for AKS, PostgreSQL, Log Analytics
- Lab lifecycle scripts (start/stop/cleanup)
- Dapr components configuration
- Monitoring configurations

**Phase 3: User Story 1 - Deploy Baseline** ✅ (9/9)
- Infrastructure deployed
- Redis deployed
- NGINX Ingress deployed
- Dapr Store application deployed
- All pods running and healthy

**Phase 4: User Story 2 - PostgreSQL Migration** ⏭️ SKIPPED (8/12)
- Code modifications completed but not deployed
- Reason: Not required for AI integration
- SQLite sufficient for single replica deployment

**Phase 5: User Story 3 - Monitoring** ✅ (3/9 partial)
- Prometheus deployed
- Grafana deployed
- ServiceMonitor configured

**Phase 6: User Story 4 - Cost Management** ⏸️ (0/10)
- Scripts created and ready to use
- Not tested in deployment

**Phase 7: Polish** ⏸️ (0/9)
- Deferred to focus on AI integration

## 📁 Created Files

### Infrastructure as Code
```
infrastructure/bicep/
├── main.bicep              # Main deployment orchestration
├── aks.bicep               # AKS cluster with Dapr extension
├── postgresql.bicep        # PostgreSQL Flexible Server
├── monitoring.bicep        # Log Analytics workspace
└── parameters.json         # Deployment parameters
```

### Lab Management Scripts
```
scripts/
├── lab-start.sh            # Start AKS + PostgreSQL
├── lab-stop.sh             # Stop AKS + PostgreSQL
├── lab-cleanup.sh          # Delete all resources
└── setup-budget-alerts.sh  # Configure cost alerts
```

### Monitoring Configuration
```
monitoring/
├── prometheus-values.yaml              # Prometheus config
├── servicemonitor.yaml                 # Dapr metrics scraping
└── grafana-dashboards/
    ├── dapr-store-overview.json        # Store overview dashboard
    └── service-health.json             # Service health dashboard
```

### Dapr Components
```
dapr-store/components/
└── statestore-postgres.yaml            # PostgreSQL state store config
```

### Code Modifications (Not Deployed)
```
dapr-store/cmd/products/
├── main.go                 # Modified with Dapr support
└── impl/
    └── dapr.go             # New Dapr state store implementation
```

### Configuration
```
.env                        # Azure credentials and config
.env.example                # Template for .env
.gitignore                  # Git ignore patterns
```

## 💰 Cost Management

### Current Running Costs
- **AKS**: ~$0.10/hour (2 nodes, Standard_DC2s_v3)
- **PostgreSQL**: ~$0.02/hour (Burstable B1ms)
- **Storage**: ~$0.01/hour (persistent)
- **Total**: ~$0.13/hour (~$3.12/day if left running)

### Stop Resources (Save Money)
```bash
cd /home/thiago/azure/zero-to-hero-ai-aks-q
source .env
./scripts/lab-stop.sh
```

### Start Resources
```bash
cd /home/thiago/azure/zero-to-hero-ai-aks-q
source .env
./scripts/lab-start.sh
```

### Complete Cleanup
```bash
cd /home/thiago/azure/zero-to-hero-ai-aks-q
source .env
az group delete --name "$RG" --yes --no-wait
```

## 🎯 Ready for Module 1: AI Integration

### What's Working
✅ Functional e-commerce application  
✅ All microservices operational  
✅ Monitoring and observability in place  
✅ Dapr service mesh configured  
✅ Infrastructure can be stopped/started easily  

### What's NOT Needed for AI
❌ PostgreSQL migration (SQLite works fine)  
❌ Horizontal scaling (single replica sufficient)  
❌ Advanced cost optimization  

### Next Steps for AI Integration
1. Add Azure OpenAI service
2. Modify products service to generate AI descriptions
3. Add caching for AI responses
4. Monitor AI API usage and costs

## 🔧 Troubleshooting

### Application Not Accessible
```bash
# Check pods
kubectl get pods

# Check ingress
kubectl get svc -l "purpose=daprstore-api-gateway"

# Get logs
kubectl logs -l daprstore=products
```

### Monitoring Not Working
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

### High Costs
```bash
# Stop immediately
source .env && ./scripts/lab-stop.sh

# Check current costs
az consumption usage list --start-date $(date -d "7 days ago" +%Y-%m-%d)
```

## 📝 Notes

- **VM Size Changed**: Original plan used Standard_D2s_v3, but subscription only had access to DC-series (confidential computing). Changed to Standard_DC2s_v3.
- **Region Changed**: PostgreSQL not available in eastus or westus2, deployed to centralus instead.
- **Redis Required**: Not part of Dapr itself - separate dependency for state management and pub/sub.
- **NGINX Ingress Required**: Separate component for API gateway functionality.

## 🔗 References

- **Dapr Store GitHub**: https://github.com/azure-samples/dapr-store
- **Dapr Documentation**: https://docs.dapr.io/
- **AKS Documentation**: https://docs.microsoft.com/azure/aks/
- **Prometheus Operator**: https://github.com/prometheus-operator/kube-prometheus

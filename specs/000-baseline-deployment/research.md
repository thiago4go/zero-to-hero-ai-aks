# Research: Baseline Deployment (Module 0)

**Feature**: 000-baseline-deployment  
**Date**: 2025-11-17  
**Phase**: 0 - Outline & Research

## Research Questions

### 1. Infrastructure as Code: Bicep vs Terraform

**Decision**: Use **Azure Bicep**

**Rationale**:
- Native Azure tool (no state file management needed)
- Simpler syntax for Azure-only deployment
- Better Azure resource coverage and day-0 support
- Integrated with Azure CLI (az deployment create)
- Easier for Azure-focused lab participants
- No external dependencies (Terraform Cloud, state storage)

**Alternatives Considered**:
- **Terraform**: Rejected - adds complexity with state management, overkill for Azure-only lab
- **ARM Templates**: Rejected - verbose JSON, Bicep is ARM's successor
- **Azure CLI scripts**: Rejected - not declarative, harder to maintain

**Implementation**:
```bash
az deployment group create \
  --resource-group $RG \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.json
```

---

### 2. AKS Cluster Configuration

**Decision**: 2-node cluster, Standard_D2s_v3, Dapr extension, stop/start enabled

**Rationale**:
- **Node Size**: Standard_D2s_v3 (2 vCPU, 8GB RAM) sufficient for baseline workload
- **Node Count**: 2 nodes for HA, cost-effective for lab
- **Dapr Extension**: Managed Dapr (no manual installation)
- **Stop/Start**: Critical for lab cost management (Constitution v1.3.0)
- **Network**: Azure CNI for better integration (not kubenet)

**Configuration**:
```bicep
resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: aksClusterName
  location: location
  properties: {
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 2
        vmSize: 'Standard_D2s_v3'
        mode: 'System'
        osType: 'Linux'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
    }
  }
}

// Enable Dapr extension
resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'dapr'
  scope: aks
  properties: {
    extensionType: 'microsoft.dapr'
    autoUpgradeMinorVersion: true
  }
}
```

**Alternatives Considered**:
- **3+ nodes**: Rejected - unnecessary cost for lab
- **Kubenet**: Rejected - Azure CNI better for Azure integration
- **Manual Dapr**: Rejected - extension is managed and easier

---

### 3. PostgreSQL Configuration

**Decision**: Flexible Server, Burstable B1ms, 32GB storage, stop/start enabled

**Rationale**:
- **Flexible Server**: Supports stop/start (Single Server deprecated)
- **Burstable B1ms**: 1 vCore, 2GB RAM - sufficient for ~100 products
- **32GB Storage**: Adequate for lab, can grow if needed
- **7-day Backup**: Default retention, adequate for lab
- **Stop/Start**: Can stop for up to 7 days (auto-starts after)

**Configuration**:
```bicep
resource postgresql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: postgresqlServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '15'
    administratorLogin: 'daprstore'
    administratorLoginPassword: postgresqlPassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled' // Not needed for lab
    }
  }
}

// Allow AKS to connect
resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: postgresql
  name: 'AllowAKS'
  properties: {
    startIpAddress: '0.0.0.0' // Will be restricted to AKS subnet in production
    endIpAddress: '255.255.255.255'
  }
}
```

**Alternatives Considered**:
- **General Purpose tier**: Rejected - 2x cost, overkill for lab
- **Single Server**: Rejected - deprecated, no stop/start
- **Cosmos DB PostgreSQL**: Rejected - expensive, unnecessary for lab

---

### 4. Products Service PostgreSQL Migration

**Decision**: Use Dapr PostgreSQL state store, load products.csv on startup

**Rationale**:
- **Dapr State Store**: Consistent with architecture (users/cart already use Dapr state)
- **products.csv**: Existing data source, no migration needed
- **Startup Load**: Simple approach - check if products exist, load if empty
- **No Schema Migration**: Dapr handles schema (key-value store)

**Implementation Pattern**:
```go
// cmd/products/main.go
func initializeProducts(daprClient dapr.Client) error {
    // Check if products already loaded
    products, err := daprClient.GetState(ctx, "statestore", "products-initialized", nil)
    if err == nil && products != nil {
        log.Info("Products already initialized")
        return nil
    }
    
    // Load from CSV
    file, err := os.Open("data/products.csv")
    if err != nil {
        return fmt.Errorf("failed to open products.csv: %w", err)
    }
    defer file.Close()
    
    reader := csv.NewReader(file)
    records, err := reader.ReadAll()
    if err != nil {
        return fmt.Errorf("failed to read CSV: %w", err)
    }
    
    // Save each product to Dapr state store
    for _, record := range records[1:] { // Skip header
        product := Product{
            ID:          record[0],
            Name:        record[1],
            Description: record[2],
            Price:       parseFloat(record[3]),
            Category:    record[4],
            Image:       record[5],
            OnOffer:     parseBool(record[6]),
        }
        
        err = daprClient.SaveState(ctx, "statestore", product.ID, product, nil)
        if err != nil {
            return fmt.Errorf("failed to save product %s: %w", product.ID, err)
        }
    }
    
    // Mark as initialized
    err = daprClient.SaveState(ctx, "statestore", "products-initialized", "true", nil)
    return err
}
```

**Dapr Component Configuration**:
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.postgresql
  version: v1
  metadata:
  - name: connectionString
    secretKeyRef:
      name: postgres-secret
      key: connectionString
  - name: actorStateStore
    value: "true"
```

**Alternatives Considered**:
- **Direct PostgreSQL queries**: Rejected - bypasses Dapr, inconsistent with architecture
- **Keep SQLite**: Rejected - violates Constitution Principle VI (scalability)
- **Manual migration script**: Rejected - startup load simpler for lab

---

### 5. Monitoring Stack Configuration

**Decision**: kube-prometheus-stack Helm chart with custom dashboards

**Rationale**:
- **kube-prometheus-stack**: Industry standard, includes Prometheus + Grafana + Alertmanager
- **Helm Chart**: Easy deployment, well-maintained
- **Custom Dashboards**: Pre-configured for dapr-store services
- **ServiceMonitor CRDs**: Automatic scraping of Dapr metrics

**Deployment**:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml
```

**Custom Values** (`monitoring/prometheus-values.yaml`):
```yaml
prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
    serviceMonitorSelectorNilUsesHelmValues: false # Scrape all ServiceMonitors

grafana:
  adminPassword: "admin" # Change in production
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        folder: 'Dapr Store'
        type: file
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      dapr-store-overview:
        file: dashboards/dapr-store-overview.json
      service-health:
        file: dashboards/service-health.json
```

**ServiceMonitor for Dapr**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dapr-services
  namespace: monitoring
spec:
  selector:
    matchLabels:
      dapr.io/enabled: "true"
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

**Alternatives Considered**:
- **Azure Monitor only**: Rejected - less flexible, harder to customize dashboards
- **Manual Prometheus deployment**: Rejected - Helm chart is easier
- **Separate Prometheus/Grafana**: Rejected - kube-prometheus-stack bundles everything

---

### 6. Lab Lifecycle Scripts

**Decision**: Bash scripts for start/stop/cleanup with error handling

**lab-start.sh**:
```bash
#!/bin/bash
set -e

echo "🚀 Starting AI on AKS Lab..."

# Load config
source .env

# Start AKS
echo "Starting AKS cluster..."
az aks start --name $AKS_CLUSTER --resource-group $RG
echo "✅ AKS started"

# Start PostgreSQL
echo "Starting PostgreSQL server..."
az postgres flexible-server start --name $POSTGRES_SERVER --resource-group $RG
echo "✅ PostgreSQL started"

# Wait for AKS to be ready
echo "Waiting for AKS to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Get gateway IP
GATEWAY_IP=$(kubectl get svc -n default store-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "✅ Lab started! Access store at: http://$GATEWAY_IP"
```

**lab-stop.sh**:
```bash
#!/bin/bash
set -e

echo "🛑 Stopping AI on AKS Lab..."

# Load config
source .env

# Stop AKS
echo "Stopping AKS cluster..."
az aks stop --name $AKS_CLUSTER --resource-group $RG
echo "✅ AKS stopped"

# Stop PostgreSQL
echo "Stopping PostgreSQL server..."
az postgres flexible-server stop --name $POSTGRES_SERVER --resource-group $RG
echo "✅ PostgreSQL stopped"

echo "💰 Resources stopped. No compute costs will accrue."
```

**lab-cleanup.sh**:
```bash
#!/bin/bash
set -e

echo "🧹 Cleaning up AI on AKS Lab..."

# Load config
source .env

# Confirm deletion
read -p "This will DELETE all lab resources. Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Delete resource group (deletes everything)
echo "Deleting resource group $RG..."
az group delete --name $RG --yes --no-wait

echo "✅ Cleanup initiated. Resources will be deleted in ~10 minutes."
echo "Verify deletion: az resource list --tag lab=ai-aks"
```

**Rationale**:
- **Bash**: Simple, portable, no dependencies
- **Error Handling**: `set -e` exits on error
- **Confirmation**: Cleanup requires explicit "yes"
- **Feedback**: Clear progress messages

**Alternatives Considered**:
- **PowerShell**: Rejected - Bash more common in Linux/Mac environments
- **Python scripts**: Rejected - adds dependency, overkill for simple operations
- **Makefile**: Rejected - less intuitive for non-developers

---

## Technology Stack Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| IaC | Azure Bicep | Latest | Infrastructure provisioning |
| Orchestration | AKS | 1.28+ | Kubernetes cluster |
| Database | PostgreSQL Flexible Server | 15 | Product data storage |
| Service Mesh | Dapr | 1.12+ | Microservices patterns |
| Monitoring | kube-prometheus-stack | Latest | Observability |
| Deployment | Helm | 3.12+ | Application deployment |
| Scripts | Bash | 4.0+ | Lab lifecycle management |

## Implementation Risks

| Risk | Mitigation |
|------|-----------|
| AKS start time >10 minutes | Document expected time, provide progress indicators |
| PostgreSQL connection failures | Health checks, retry logic, clear error messages |
| Helm deployment failures | Rollback strategy, pre-deployment validation |
| Cost overruns | Budget alerts, daily cost review, stop/start enforcement |
| products.csv missing/malformed | Validation on startup, clear error messages |
| Dapr sidecar injection failures | Verify annotations, check Dapr extension status |

## Cost Breakdown

| Resource | SKU | Hourly Cost | 3-Hour Cost | Notes |
|----------|-----|-------------|-------------|-------|
| AKS (2 nodes) | Standard_D2s_v3 | ~$0.20 | ~$0.60 | Stopped when not in use |
| PostgreSQL | Burstable B1ms | ~$0.02 | ~$0.06 | Stopped when not in use |
| Load Balancer | Standard | ~$0.03 | ~$0.09 | Minimal data transfer |
| Storage | 32GB + 20GB | ~$0.01 | ~$0.03 | Persistent even when stopped |
| **Total** | | **~$0.26/hr** | **~$0.78** | With stop/start |
| **Total (no stop)** | | **~$0.26/hr** | **~$6.24/day** | If left running 24/7 |

**Estimated Module 0 Cost**: $5-10 (includes deployment time, testing, buffer)

## Next Steps

Phase 1 will produce:
- **data-model.md**: PostgreSQL schema via Dapr state store
- **quickstart.md**: Complete deployment guide with stop/start instructions
- **contracts/**: N/A for infrastructure module

# Quickstart: Baseline Deployment (Module 0)

**Feature**: 000-baseline-deployment  
**Date**: 2025-11-17  
**Estimated Setup Time**: 30 minutes  
**Estimated Cost**: $5-10 for 3-hour session with stop/start

## Prerequisites

- Azure subscription with Owner or Contributor role
- Azure CLI 2.47.0+ installed and authenticated (`az login`)
- kubectl 1.28+ installed
- Helm 3.12+ installed
- Bash shell (Linux/Mac/WSL)

## Step 1: Set Environment Variables

```bash
# Create .env file
cat > .env << 'EOF'
# Azure Configuration
SUBSCRIPTION_ID="<your-subscription-id>"
LOCATION="eastus"
RG="rg-ai-aks-lab"

# Resource Names
AKS_CLUSTER="aks-ai-lab"
POSTGRES_SERVER="postgres-ai-lab-$(whoami)"
LOG_ANALYTICS="logs-ai-lab"

# Database Configuration
POSTGRES_ADMIN_USER="daprstore"
POSTGRES_ADMIN_PASSWORD="<generate-strong-password>"
POSTGRES_DB="daprstore"
EOF

# Load variables
source .env

# Set Azure subscription
az account set --subscription $SUBSCRIPTION_ID
```

## Step 2: Deploy Infrastructure with Bicep

```bash
# Create resource group
az group create --name $RG --location $LOCATION --tags lab=ai-aks

# Deploy infrastructure (AKS + PostgreSQL + Log Analytics)
az deployment group create \
  --resource-group $RG \
  --template-file infrastructure/bicep/main.bicep \
  --parameters \
    aksClusterName=$AKS_CLUSTER \
    postgresqlServerName=$POSTGRES_SERVER \
    postgresqlAdminPassword=$POSTGRES_ADMIN_PASSWORD \
    logAnalyticsName=$LOG_ANALYTICS \
    location=$LOCATION

# Get AKS credentials
az aks get-credentials --resource-group $RG --name $AKS_CLUSTER

# Verify Dapr extension
az k8s-extension show \
  --cluster-name $AKS_CLUSTER \
  --resource-group $RG \
  --cluster-type managedClusters \
  --name dapr
```

**Expected Duration**: 10-15 minutes

## Step 3: Configure PostgreSQL Connection

```bash
# Get PostgreSQL FQDN
POSTGRES_FQDN=$(az postgres flexible-server show \
  --name $POSTGRES_SERVER \
  --resource-group $RG \
  --query fullyQualifiedDomainName \
  --output tsv)

# Create connection string
CONNECTION_STRING="host=${POSTGRES_FQDN} port=5432 user=${POSTGRES_ADMIN_USER} password=${POSTGRES_ADMIN_PASSWORD} dbname=${POSTGRES_DB} sslmode=require"

# Create Kubernetes secret
kubectl create secret generic postgres-secret \
  --from-literal=connectionString="$CONNECTION_STRING"

# Deploy Dapr PostgreSQL component
kubectl apply -f dapr-store/components/statestore-postgres.yaml
```

## Step 4: Deploy Monitoring Stack

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml \
  --wait

# Deploy ServiceMonitor for Dapr
kubectl apply -f monitoring/servicemonitor.yaml

# Get Grafana password
kubectl get secret -n monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

**Expected Duration**: 5 minutes

## Step 5: Deploy Dapr Store Application

```bash
# Deploy application with Helm
helm install daprstore dapr-store/deploy/helm/daprstore \
  --set products.env.DAPR_STORE_NAME=statestore \
  --wait

# Wait for all pods to be ready
kubectl wait --for=condition=Ready pods --all --timeout=300s

# Get gateway external IP
GATEWAY_IP=$(kubectl get svc store-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Store URL: http://$GATEWAY_IP"
```

**Expected Duration**: 5 minutes

## Step 6: Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Check products service logs (should show CSV load)
kubectl logs -l app=store-products --tail=50

# Test product API
curl http://$GATEWAY_IP/v1.0/invoke/products-service/method/catalog | jq

# Access store frontend
open "http://$GATEWAY_IP"  # Mac
# or
xdg-open "http://$GATEWAY_IP"  # Linux
```

**Verification Checklist**:
- [ ] All pods in Running state
- [ ] Products service loaded ~100 products from CSV
- [ ] Store frontend accessible via browser
- [ ] Can browse products, add to cart, submit order
- [ ] Order status changes from OrderReceived to OrderProcessing

## Step 7: Access Monitoring

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Access Grafana at http://localhost:3000
# Username: admin
# Password: <from Step 4>

# View dashboards:
# - Dapr Store Overview
# - Service Health
```

---

## Lab Lifecycle Management

### Stop Lab (End of Session) - MANDATORY 💰

```bash
# Run stop script
./scripts/lab-stop.sh

# Or manually:
az aks stop --name $AKS_CLUSTER --resource-group $RG
az postgres flexible-server stop --name $POSTGRES_SERVER --resource-group $RG

echo "✅ Lab stopped. No compute costs will accrue."
```

**IMPORTANT**: Always stop resources when not in use to avoid unnecessary costs!

### Start Lab (Next Session)

```bash
# Run start script
./scripts/lab-start.sh

# Or manually:
az aks start --name $AKS_CLUSTER --resource-group $RG
az postgres flexible-server start --name $POSTGRES_SERVER --resource-group $RG

# Wait for AKS to be ready (~5 minutes)
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Get gateway IP
GATEWAY_IP=$(kubectl get svc store-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Store URL: http://$GATEWAY_IP"
```

**Expected Duration**: 5-10 minutes

### Cleanup Lab (After Completion)

```bash
# Run cleanup script
./scripts/lab-cleanup.sh

# Or manually:
az group delete --name $RG --yes --no-wait

# Verify deletion
az resource list --tag lab=ai-aks
```

---

## Cost Monitoring

### Set Up Budget Alerts

```bash
# Create budget with alerts
az consumption budget create \
  --budget-name "ai-aks-lab-budget" \
  --amount 150 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date -d "+1 month" +%Y-%m-01) \
  --resource-group $RG \
  --notifications \
    threshold=50 \
    operator=GreaterThan \
    contact-emails="your-email@example.com" \
  --notifications \
    threshold=80 \
    operator=GreaterThan \
    contact-emails="your-email@example.com" \
  --notifications \
    threshold=100 \
    operator=GreaterThan \
    contact-emails="your-email@example.com"
```

### Check Current Costs

```bash
# View costs for resource group
az consumption usage list \
  --start-date $(date -d "7 days ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceId, '$RG')]" \
  --output table

# Or use Azure Portal: Cost Management + Billing
```

---

## Troubleshooting

### Issue: AKS start takes >10 minutes

**Solution**: This is normal for first start. Subsequent starts are faster (~5 min).

### Issue: PostgreSQL connection refused

**Cause**: Firewall rules or connection string incorrect

**Solution**:
```bash
# Verify firewall rules
az postgres flexible-server firewall-rule list \
  --name $POSTGRES_SERVER \
  --resource-group $RG

# Test connection from AKS
kubectl run -it --rm psql --image=postgres:15 --restart=Never -- \
  psql "$CONNECTION_STRING" -c "SELECT version();"
```

### Issue: Products service not loading CSV

**Cause**: products.csv not found or malformed

**Solution**:
```bash
# Check products service logs
kubectl logs -l app=store-products --tail=100

# Verify CSV exists
kubectl exec -it $(kubectl get pod -l app=store-products -o name | head -1) -- \
  ls -la /app/data/products.csv
```

### Issue: Dapr sidecar not injected

**Cause**: Dapr extension not enabled or annotations missing

**Solution**:
```bash
# Verify Dapr extension
kubectl get pods -n dapr-system

# Check pod annotations
kubectl get pod -l app=store-products -o yaml | grep dapr.io
```

### Issue: High costs

**Emergency Actions**:
1. Stop AKS immediately: `az aks stop --name $AKS_CLUSTER --resource-group $RG`
2. Stop PostgreSQL: `az postgres flexible-server stop --name $POSTGRES_SERVER --resource-group $RG`
3. Review costs: Azure Portal → Cost Management
4. Delete unused resources: `az group delete --name $RG`

---

## Next Steps

After completing Module 0:

1. **Verify Baseline**: Complete all verification steps above
2. **Test Stop/Start**: Practice stopping and starting resources
3. **Review Costs**: Check Azure Cost Management after 24 hours
4. **Proceed to Module 1**: AI-generated product descriptions (feature 001)

**Module 0 Complete!** ✅ You now have a working baseline for AI enhancements.

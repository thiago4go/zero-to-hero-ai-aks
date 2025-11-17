# Quickstart: AI-Generated Product Descriptions

**Feature**: 001-ai-product-descriptions  
**Date**: 2025-11-16  
**Estimated Setup Time**: 30 minutes

## Prerequisites

- Azure subscription with permissions to create resources
- Azure CLI installed and authenticated (`az login`)
- Go 1.23+ installed
- Docker installed (for local Dapr)
- Dapr CLI installed (`dapr init`)
- kubectl configured for AKS cluster (for deployment)

## Local Development Setup

### Step 1: Provision Azure OpenAI Resource

```bash
# Set variables
RESOURCE_GROUP="rg-ai-aks-lab"
LOCATION="eastus"
OPENAI_NAME="openai-dapr-store-$(whoami)"
DEPLOYMENT_NAME="gpt-4"

# Create resource group (if not exists)
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind OpenAI \
  --sku S0 \
  --yes

# Create GPT-4 deployment
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name $DEPLOYMENT_NAME \
  --model-name gpt-4 \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"

# Get endpoint
OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv)

echo "Azure OpenAI Endpoint: $OPENAI_ENDPOINT"
```

### Step 2: Configure Managed Identity (Local Development)

For local development, use Azure CLI credentials:

```bash
# Login to Azure (if not already)
az login

# Verify identity
az account show

# Set environment variable for products service
export AZURE_OPENAI_ENDPOINT="$OPENAI_ENDPOINT"
export AZURE_OPENAI_DEPLOYMENT="$DEPLOYMENT_NAME"
```

**Note**: `DefaultAzureCredential` in Go SDK will automatically use Azure CLI credentials locally.

### Step 3: Install Go Dependencies

```bash
cd dapr-store/cmd/products

# Add Azure SDK dependencies
go get github.com/Azure/azure-sdk-for-go/sdk/azidentity@latest
go get github.com/Azure/azure-sdk-for-go/sdk/ai/azopenai@latest
go get github.com/prometheus/client_golang/prometheus@latest
go get github.com/prometheus/client_golang/prometheus/promhttp@latest

# Verify dependencies
go mod tidy
```

### Step 4: Start Local Dapr and Redis

```bash
# Initialize Dapr (if not already done)
dapr init

# Start Redis for state store
docker run -d --name redis -p 6379:6379 redis:7-alpine

# Verify Dapr components
dapr components -k
```

### Step 5: Run Products Service with Dapr

```bash
cd dapr-store/cmd/products

# Run with Dapr sidecar
dapr run \
  --app-id products-service \
  --app-port 9002 \
  --dapr-http-port 3500 \
  --components-path ../../components \
  -- go run .
```

**Expected Output**:
```
INFO[0000] starting Dapr Runtime -- version 1.12.0 -- commit abc123
INFO[0001] application protocol: http. waiting on port 9002
INFO[0002] application discovered on port 9002
✅ You're up and running! Both Dapr and your app logs will appear here.
```

### Step 6: Test AI Description Generation

```bash
# Get a product (should trigger AI generation on first request)
curl http://localhost:9002/get/prd1 | jq

# Check cache (second request should be faster)
curl http://localhost:9002/get/prd1 | jq

# View Prometheus metrics
curl http://localhost:9002/metrics | grep ai_description
```

**Expected Metrics**:
```
ai_description_requests_total{status="success"} 1
ai_description_cache_hits_total 1
ai_description_cache_misses_total 1
ai_description_latency_seconds_bucket{le="2"} 1
```

---

## AKS Deployment Setup

### Step 1: Configure Managed Identity for AKS

```bash
# Get AKS cluster name
AKS_CLUSTER="aks-ai-lab"

# Enable workload identity (if not already enabled)
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --enable-oidc-issuer \
  --enable-workload-identity

# Get OIDC issuer URL
OIDC_ISSUER=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --query oidcIssuerProfile.issuerUrl \
  --output tsv)

# Create managed identity
IDENTITY_NAME="id-products-service"
az identity create \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Get identity client ID
IDENTITY_CLIENT_ID=$(az identity show \
  --name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query clientId \
  --output tsv)

# Assign "Cognitive Services OpenAI User" role
OPENAI_ID=$(az cognitiveservices account show \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id \
  --output tsv)

az role assignment create \
  --role "Cognitive Services OpenAI User" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope $OPENAI_ID

# Create federated credential for Kubernetes service account
az identity federated-credential create \
  --name "products-service-federated" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer $OIDC_ISSUER \
  --subject "system:serviceaccount:default:products-service" \
  --audience "api://AzureADTokenExchange"
```

### Step 2: Update Kubernetes Deployment

Add to `deploy/helm/daprstore/templates/products.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: products-service
  annotations:
    azure.workload.identity/client-id: "<IDENTITY_CLIENT_ID>"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store-products
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: products-service
      containers:
      - name: service
        image: <ACR_NAME>.azurecr.io/products-service:latest
        env:
        - name: AZURE_OPENAI_ENDPOINT
          value: "<OPENAI_ENDPOINT>"
        - name: AZURE_OPENAI_DEPLOYMENT
          value: "gpt-4"
        - name: AZURE_CLIENT_ID
          value: "<IDENTITY_CLIENT_ID>"
```

### Step 3: Deploy to AKS

```bash
# Build and push container
cd dapr-store
docker build -f build/service.Dockerfile -t <ACR_NAME>.azurecr.io/products-service:latest .
docker push <ACR_NAME>.azurecr.io/products-service:latest

# Deploy with Helm
helm upgrade daprstore deploy/helm/daprstore \
  --set products.image.tag=latest \
  --set products.env.AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
  --set products.env.AZURE_OPENAI_DEPLOYMENT=$DEPLOYMENT_NAME \
  --set products.env.AZURE_CLIENT_ID=$IDENTITY_CLIENT_ID

# Verify deployment
kubectl get pods -l app=store-products
kubectl logs -l app=store-products -f
```

---

## Verification Checklist

- [ ] Azure OpenAI resource provisioned with GPT-4 deployment
- [ ] Managed Identity created and assigned "Cognitive Services OpenAI User" role
- [ ] Products service runs locally with Dapr
- [ ] AI descriptions generated on first product request
- [ ] Cache hit on second request (faster response)
- [ ] Prometheus metrics visible at `/metrics` endpoint
- [ ] Graceful fallback works (test by stopping Azure OpenAI)
- [ ] Products service deployed to AKS with workload identity
- [ ] No API keys in code, logs, or environment variables

---

## Troubleshooting

### Issue: "Authentication failed" error

**Cause**: Managed Identity not configured or missing RBAC role

**Solution**:
```bash
# Verify identity has correct role
az role assignment list \
  --assignee $IDENTITY_CLIENT_ID \
  --scope $OPENAI_ID

# Re-assign role if missing
az role assignment create \
  --role "Cognitive Services OpenAI User" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope $OPENAI_ID
```

### Issue: "Rate limit exceeded" (429 error)

**Cause**: Azure OpenAI quota exceeded

**Solution**:
- Check cache hit rate (should be >80%)
- Increase deployment capacity: `az cognitiveservices account deployment update --sku-capacity 20`
- Implement request throttling in products service

### Issue: Cache not working

**Cause**: Dapr state store not configured

**Solution**:
```bash
# Verify Redis is running
docker ps | grep redis

# Check Dapr components
dapr components -k

# Test Dapr state store directly
curl -X POST http://localhost:3500/v1.0/state/statestore \
  -H "Content-Type: application/json" \
  -d '[{"key":"test","value":"hello"}]'

curl http://localhost:3500/v1.0/state/statestore/test
```

### Issue: Slow response times

**Cause**: Azure OpenAI latency or cache misses

**Solution**:
- Check Prometheus metrics: `ai_description_latency_seconds`
- Verify cache hit rate: `ai_description_cache_hits_total / ai_description_requests_total`
- Consider increasing cache TTL from 24h to 7 days

---

## Next Steps

After completing this quickstart:

1. **Run Tests**: Execute unit and integration tests (see tasks.md)
2. **Monitor Metrics**: Set up Grafana dashboard for AI metrics
3. **Optimize Prompts**: Experiment with system message for better descriptions
4. **Scale Testing**: Load test with 100 concurrent requests
5. **Cost Analysis**: Review Azure OpenAI usage and costs in Azure Portal

**Ready for `/speckit.tasks`** to break down implementation into tasks!

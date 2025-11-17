#!/bin/bash
set -e

echo "🚀 Starting AI on AKS Lab..."

# Load config
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please create it from .env.example"
    exit 1
fi
source .env

# Start AKS
echo "Starting AKS cluster..."
az aks start --name "$AKS_CLUSTER" --resource-group "$RG"
echo "✅ AKS started"

# Start PostgreSQL
echo "Starting PostgreSQL server..."
az postgres flexible-server start --name "$POSTGRES_SERVER" --resource-group "$RG"
echo "✅ PostgreSQL started"

# Wait for AKS to be ready
echo "Waiting for AKS to be ready..."
az aks get-credentials --name "$AKS_CLUSTER" --resource-group "$RG" --overwrite-existing
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Get gateway IP
GATEWAY_IP=$(kubectl get svc -n default store-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "not-deployed")
if [ "$GATEWAY_IP" != "not-deployed" ]; then
    echo "✅ Lab started! Access store at: http://$GATEWAY_IP"
else
    echo "✅ Lab started! Application not yet deployed."
fi

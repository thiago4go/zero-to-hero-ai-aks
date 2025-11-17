#!/bin/bash
set -e

echo "🛑 Stopping AI on AKS Lab..."

# Load config
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please create it from .env.example"
    exit 1
fi
source .env

# Stop AKS
echo "Stopping AKS cluster..."
az aks stop --name "$AKS_CLUSTER" --resource-group "$RG"
echo "✅ AKS stopped"

# Stop PostgreSQL
echo "Stopping PostgreSQL server..."
az postgres flexible-server stop --name "$POSTGRES_SERVER" --resource-group "$RG"
echo "✅ PostgreSQL stopped"

echo "💰 Resources stopped. No compute costs will accrue."
echo "⚠️  Storage costs still apply (~$0.01/hour)"

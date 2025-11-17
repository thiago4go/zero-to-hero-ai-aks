#!/bin/bash
set -e

echo "🧹 Cleaning up AI on AKS Lab..."

# Load config
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please create it from .env.example"
    exit 1
fi
source .env

# Confirm deletion
read -p "This will DELETE all lab resources. Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Delete resource group (deletes everything)
echo "Deleting resource group $RG..."
az group delete --name "$RG" --yes --no-wait

echo "✅ Cleanup initiated. Resources will be deleted in ~10 minutes."
echo "Verify deletion: az resource list --tag lab=ai-aks"

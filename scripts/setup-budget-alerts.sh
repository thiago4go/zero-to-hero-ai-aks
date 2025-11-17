#!/bin/bash
set -e

echo "💰 Setting up budget alerts..."

# Load config
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please create it from .env.example"
    exit 1
fi
source .env

# Check if ALERT_EMAIL is set
if [ -z "$ALERT_EMAIL" ]; then
    echo "❌ Error: ALERT_EMAIL not set in .env file"
    exit 1
fi

# Create budget with alerts
az consumption budget create \
  --budget-name "ai-aks-lab-budget" \
  --amount 150 \
  --time-grain Monthly \
  --start-date "$(date +%Y-%m-01)" \
  --end-date "$(date -d "+1 month" +%Y-%m-01)" \
  --resource-group "$RG" \
  --category Cost \
  --notifications \
    threshold=50 \
    operator=GreaterThan \
    contact-emails="$ALERT_EMAIL" \
  --notifications \
    threshold=80 \
    operator=GreaterThan \
    contact-emails="$ALERT_EMAIL" \
  --notifications \
    threshold=100 \
    operator=GreaterThan \
    contact-emails="$ALERT_EMAIL"

echo "✅ Budget alerts configured for $ALERT_EMAIL"
echo "   - 50% threshold: \$75"
echo "   - 80% threshold: \$120"
echo "   - 100% threshold: \$150"

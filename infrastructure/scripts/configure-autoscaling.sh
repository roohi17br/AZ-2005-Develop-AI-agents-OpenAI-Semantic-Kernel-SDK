#!/bin/bash
# Configure auto-scaling for App Service Plan
# Based on scaling strategies in roo.md

# Required variables
RESOURCE_GROUP="rg-openai-apps"
APP_SERVICE_PLAN="asp-openai-apps"

echo "Configuring auto-scaling for $APP_SERVICE_PLAN..."

# Configure auto-scaling based on CPU
echo "Creating auto-scale settings..."
az monitor autoscale create \
  --resource-group $RESOURCE_GROUP \
  --resource $APP_SERVICE_PLAN \
  --resource-type Microsoft.Web/serverfarms \
  --name "autoscale-cpu-$APP_SERVICE_PLAN" \
  --min-count 1 \
  --max-count 5 \
  --count 2

# Add scale-out rule (CPU > 70%)
echo "Adding scale-out rule..."
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name "autoscale-cpu-$APP_SERVICE_PLAN" \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Add scale-in rule (CPU < 30%)
echo "Adding scale-in rule..."
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name "autoscale-cpu-$APP_SERVICE_PLAN" \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1

# Add scale-out rule based on memory (> 80%)
echo "Adding memory-based scale-out rule..."
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name "autoscale-cpu-$APP_SERVICE_PLAN" \
  --condition "MemoryPercentage > 80 avg 5m" \
  --scale out 1

# Add scale-in rule based on memory (< 40%)
echo "Adding memory-based scale-in rule..."
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name "autoscale-cpu-$APP_SERVICE_PLAN" \
  --condition "MemoryPercentage < 40 avg 5m" \
  --scale in 1

echo ""
echo "Auto-scaling configuration completed!"
echo "================================================"
echo "App Service Plan: $APP_SERVICE_PLAN"
echo "Min instances: 1"
echo "Max instances: 5"
echo "Default instances: 2"
echo "================================================"
echo "Scale-out triggers:"
echo "  - CPU > 70% (avg 5min)"
echo "  - Memory > 80% (avg 5min)"
echo ""
echo "Scale-in triggers:"
echo "  - CPU < 30% (avg 5min)"
echo "  - Memory < 40% (avg 5min)"
echo "================================================"

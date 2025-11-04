#!/bin/bash
# Configure monitoring with Application Insights
# Based on monitoring best practices in roo.md

# Required variables
RESOURCE_GROUP="rg-openai-apps"
LOCATION="eastus"
APP_NAME=$1
APP_INSIGHTS_NAME="ai-openai-apps"

if [ -z "$APP_NAME" ]; then
  echo "Usage: ./configure-monitoring.sh <APP_NAME>"
  exit 1
fi

echo "Configuring monitoring for $APP_NAME..."

# Create Application Insights
echo "Creating Application Insights..."
az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Get instrumentation key and connection string
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey \
  --output tsv)

CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query connectionString \
  --output tsv)

echo "Instrumentation Key: $INSTRUMENTATION_KEY"

# Configure app to use Application Insights
echo "Configuring web app..."
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3"

# Enable diagnostic settings
echo "Enabling diagnostic logging..."
LOG_ANALYTICS_WORKSPACE=$(az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-openai-apps" \
  --location $LOCATION \
  --query id \
  --output tsv)

az monitor diagnostic-settings create \
  --name "diag-$APP_NAME" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$APP_NAME" \
  --logs '[
    {"category":"AppServiceHTTPLogs","enabled":true,"retentionPolicy":{"enabled":false,"days":0}},
    {"category":"AppServiceConsoleLogs","enabled":true,"retentionPolicy":{"enabled":false,"days":0}},
    {"category":"AppServiceAppLogs","enabled":true,"retentionPolicy":{"enabled":false,"days":0}}
  ]' \
  --metrics '[{"category":"AllMetrics","enabled":true,"retentionPolicy":{"enabled":false,"days":0}}]' \
  --workspace $LOG_ANALYTICS_WORKSPACE

# Enable application logging
az webapp log config \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --application-logging filesystem \
  --level information

echo ""
echo "Monitoring configuration completed!"
echo "================================================"
echo "Application Insights: $APP_INSIGHTS_NAME"
echo "Connection String: $CONNECTION_STRING"
echo "Log Analytics Workspace: $LOG_ANALYTICS_WORKSPACE"
echo "================================================"
echo ""
echo "View logs with:"
echo "  az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "View Application Insights in Azure Portal:"
echo "  https://portal.azure.com/#resource$LOG_ANALYTICS_WORKSPACE/overview"

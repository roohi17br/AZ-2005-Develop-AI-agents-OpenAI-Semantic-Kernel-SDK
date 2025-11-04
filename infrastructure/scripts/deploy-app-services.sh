#!/bin/bash
# Deploy multiple web applications to Azure App Service
# Based on the guide in roo.md

# Required environment variables (set these before running)
if [ -z "$OPENAI_ENDPOINT" ] || [ -z "$OPENAI_KEY" ]; then
  echo "Error: Please set OPENAI_ENDPOINT and OPENAI_KEY environment variables"
  echo "You can get these values by running deploy-azure-openai.sh first"
  exit 1
fi

# Set variables
RESOURCE_GROUP="rg-openai-apps"
LOCATION="eastus"
APP_SERVICE_PLAN="asp-openai-apps"

echo "Deploying Azure App Service resources..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "App Service Plan: $APP_SERVICE_PLAN"

# Create App Service Plan (Standard tier for production)
echo "Creating App Service Plan..."
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku S1 \
  --is-linux

# Create C# Web App #1 - Chat Application
echo "Creating C# Chat Application..."
APP_NAME_1="webapp-chat-$(openssl rand -hex 4)"

az webapp create \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"

az webapp config appsettings set \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"

# Create C# Web App #2 - Document Summarizer
echo "Creating C# Document Summarizer..."
APP_NAME_2="webapp-summarizer-$(openssl rand -hex 4)"

az webapp create \
  --name $APP_NAME_2 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"

az webapp config appsettings set \
  --name $APP_NAME_2 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-4"

# Create C# Web App #3 - Code Assistant
echo "Creating C# Code Assistant..."
APP_NAME_3="webapp-codeassist-$(openssl rand -hex 4)"

az webapp create \
  --name $APP_NAME_3 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"

az webapp config appsettings set \
  --name $APP_NAME_3 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-4"

echo ""
echo "Deployment completed successfully!"
echo "================================================"
echo "App 1 (Chat): https://$APP_NAME_1.azurewebsites.net"
echo "App 2 (Summarizer): https://$APP_NAME_2.azurewebsites.net"
echo "App 3 (Code Assistant): https://$APP_NAME_3.azurewebsites.net"
echo "================================================"

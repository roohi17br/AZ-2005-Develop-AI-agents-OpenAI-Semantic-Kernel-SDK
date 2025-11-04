#!/bin/bash
# Deploy Azure OpenAI Service and create deployments
# Based on the guide in roo.md

# Set variables
RESOURCE_GROUP="rg-openai-apps"
LOCATION="eastus"
OPENAI_NAME="openai-multiapp-$(openssl rand -hex 4)"

echo "Creating Azure OpenAI resources..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "OpenAI Service Name: $OPENAI_NAME"

# Create resource group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure OpenAI resource
echo "Creating Azure OpenAI service..."
az cognitiveservices account create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind OpenAI \
  --sku S0 \
  --location $LOCATION

# Deploy GPT-4 model
echo "Deploying GPT-4 model..."
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"

# Deploy GPT-35-turbo model
echo "Deploying GPT-35-turbo model..."
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-35-turbo \
  --model-name gpt-35-turbo \
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

# Get API key
OPENAI_KEY=$(az cognitiveservices account keys list \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv)

echo ""
echo "Deployment completed successfully!"
echo "================================================"
echo "Endpoint: $OPENAI_ENDPOINT"
echo "API Key: $OPENAI_KEY"
echo "================================================"
echo ""
echo "Save these values to your appsettings.json or .env file:"
echo "  AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT"
echo "  AZURE_OPENAI_API_KEY=$OPENAI_KEY"
echo "  AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo (or gpt-4)"

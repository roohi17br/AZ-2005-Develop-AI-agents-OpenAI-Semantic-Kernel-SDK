#!/bin/bash
# Configure App Service with Managed Identity and Key Vault
# Based on security best practices in roo.md

# Required variables
RESOURCE_GROUP="rg-openai-apps"
LOCATION="eastus"
APP_NAME=$1
OPENAI_NAME=$2
KEY_VAULT_NAME="kv-openai-$(openssl rand -hex 4)"

if [ -z "$APP_NAME" ] || [ -z "$OPENAI_NAME" ]; then
  echo "Usage: ./configure-security.sh <APP_NAME> <OPENAI_NAME>"
  exit 1
fi

echo "Configuring security for $APP_NAME..."

# Enable system-assigned managed identity
echo "Enabling Managed Identity..."
az webapp identity assign \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP

# Get the principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId \
  --output tsv)

echo "Principal ID: $PRINCIPAL_ID"

# Grant access to Azure OpenAI
echo "Granting Azure OpenAI access..."
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Cognitive Services OpenAI User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_NAME"

# Create Key Vault
echo "Creating Key Vault..."
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Get API key
OPENAI_KEY=$(az cognitiveservices account keys list \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv)

# Store OpenAI key in Key Vault
echo "Storing API key in Key Vault..."
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "OpenAIApiKey" \
  --value "$OPENAI_KEY"

# Grant Key Vault access to the web app
echo "Granting Key Vault access to web app..."
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Enforce HTTPS
echo "Enforcing HTTPS..."
az webapp update \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --https-only true

echo ""
echo "Security configuration completed!"
echo "================================================"
echo "Managed Identity: Enabled"
echo "Key Vault: $KEY_VAULT_NAME"
echo "HTTPS: Enforced"
echo "================================================"
echo ""
echo "Update your app settings to reference Key Vault:"
echo "AZURE_OPENAI_API_KEY=@Microsoft.KeyVault(SecretUri=https://$KEY_VAULT_NAME.vault.azure.net/secrets/OpenAIApiKey/)"

# Deployment Guide

This guide provides step-by-step instructions for deploying the Semantic Kernel applications to Azure App Service with Azure OpenAI integration. This complements the comprehensive [Azure App Service deployment guide](roo.md) with specific instructions for this repository.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Deployment Steps](#detailed-deployment-steps)
4. [Configuration](#configuration)
5. [Security Best Practices](#security-best-practices)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- **Azure Subscription**: Active Azure account with appropriate permissions
- **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Development Tools**:
  - For C#: .NET 8.0 SDK, Visual Studio Code or Visual Studio
  - For Python: Python 3.11+, pip
- **Git**: For version control and deployment
- **Azure OpenAI Access**: Approved access to Azure OpenAI service

## Quick Start

### Option 1: Deploy Everything with Bicep

Deploy the complete infrastructure and applications in one command:

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-openai-apps --location eastus

# Deploy infrastructure
cd infrastructure/bicep
az deployment group create \
  --resource-group rg-openai-apps \
  --template-file main.bicep
```

### Option 2: Step-by-Step with Scripts

```bash
# 1. Deploy Azure OpenAI
cd infrastructure/scripts
./deploy-azure-openai.sh

# Save the output values (ENDPOINT and API_KEY)

# 2. Deploy App Services
export OPENAI_ENDPOINT="<your-endpoint>"
export OPENAI_KEY="<your-api-key>"
./deploy-app-services.sh

# 3. Configure security (optional but recommended)
./configure-security.sh <APP_NAME> <OPENAI_NAME>

# 4. Configure monitoring
./configure-monitoring.sh <APP_NAME>

# 5. Configure auto-scaling
./configure-autoscaling.sh
```

## Detailed Deployment Steps

### Step 1: Set Up Azure OpenAI Service

Create an Azure OpenAI service and deploy the required models:

```bash
# Set variables
RESOURCE_GROUP="rg-openai-apps"
LOCATION="eastus"
OPENAI_NAME="openai-multiapp-$(openssl rand -hex 4)"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind OpenAI \
  --sku S0 \
  --location $LOCATION

# Deploy models
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-35-turbo \
  --model-name gpt-35-turbo \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"
```

### Step 2: Configure Your Applications

Update the configuration files with your Azure OpenAI credentials.

#### For Lab Projects (C#)

Edit `appsettings.json` in your lab directory:

```json
{
    "AZURE_OPENAI_DEPLOYMENT_NAME": "gpt-35-turbo",
    "AZURE_OPENAI_ENDPOINT": "https://your-endpoint.openai.azure.com/",
    "AZURE_OPENAI_API_KEY": "your-api-key-here"
}
```

#### For Python Projects

Edit `.env` file:

```bash
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo
AZURE_OPENAI_ENDPOINT=https://your-endpoint.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key-here
```

### Step 3: Test Locally

Before deploying to Azure, test your applications locally:

#### C# Applications

```bash
cd Allfiles/Labs/01/Starter
dotnet restore
dotnet build
dotnet run
```

#### Python Applications

```bash
cd Allfiles/Labs/Devops/python
pip install -r requirements.txt
python devops.py
```

### Step 4: Deploy to Azure App Service

Choose your preferred deployment method:

#### Method A: ZIP Deployment (Fastest)

```bash
# Navigate to your app directory
cd Examples/WebApps/ChatApp

# Build the application
dotnet publish -c Release -o ./publish

# Create a zip file
cd publish
zip -r ../app.zip .
cd ..

# Deploy to Azure
az webapp deployment source config-zip \
  --name <your-app-name> \
  --resource-group rg-openai-apps \
  --src app.zip
```

#### Method B: Local Git Deployment

```bash
# Enable local git deployment
az webapp deployment source config-local-git \
  --name <your-app-name> \
  --resource-group rg-openai-apps

# Add Azure remote
git remote add azure <git-url>

# Deploy
git push azure main
```

#### Method C: GitHub Actions (CI/CD)

1. Fork this repository to your GitHub account
2. Set up GitHub secrets:
   - `AZURE_WEBAPP_PUBLISH_PROFILE`: Download from Azure Portal
   - `AZURE_CREDENTIALS`: For infrastructure deployment

3. Update workflow files in `.github/workflows/`:
   - `deploy-csharp-app.yml`: For C# applications
   - `deploy-python-app.yml`: For Python applications
   - `deploy-infrastructure.yml`: For infrastructure changes

4. Push to main branch to trigger deployment

## Configuration

### Environment Variables

All applications use these standardized environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI service endpoint | `https://your-resource.openai.azure.com/` |
| `AZURE_OPENAI_API_KEY` | API key for authentication | `abc123...` |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Model deployment name | `gpt-35-turbo` or `gpt-4` |

### App Service Settings

Configure app settings via Azure CLI:

```bash
az webapp config appsettings set \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --settings \
    AZURE_OPENAI_ENDPOINT="<endpoint>" \
    AZURE_OPENAI_API_KEY="<key>" \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
```

## Security Best Practices

### 1. Use Managed Identity

Enable Managed Identity to avoid storing API keys:

```bash
# Enable managed identity
az webapp identity assign \
  --name <app-name> \
  --resource-group rg-openai-apps

# Grant access to Azure OpenAI
az role assignment create \
  --assignee <principal-id> \
  --role "Cognitive Services OpenAI User" \
  --scope <openai-resource-id>
```

Update your code to use `DefaultAzureCredential`:

**C#:**
```csharp
using Azure.Identity;

builder.Services.AddKernel()
    .AddAzureOpenAIChatCompletion(
        deploymentName: config["AZURE_OPENAI_DEPLOYMENT_NAME"],
        endpoint: config["AZURE_OPENAI_ENDPOINT"],
        credentials: new DefaultAzureCredential()
    );
```

**Python:**
```python
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
kernel.add_service(
    AzureChatCompletion(
        deployment_name=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
        endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        credential=credential
    )
)
```

### 2. Use Azure Key Vault

Store secrets in Key Vault:

```bash
# Create Key Vault
az keyvault create \
  --name kv-openai-$(openssl rand -hex 4) \
  --resource-group rg-openai-apps \
  --location eastus

# Store secret
az keyvault secret set \
  --vault-name <vault-name> \
  --name "OpenAIApiKey" \
  --value "<api-key>"

# Reference in App Service
az webapp config appsettings set \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --settings \
    AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=https://<vault-name>.vault.azure.net/secrets/OpenAIApiKey/)"
```

### 3. Enforce HTTPS

```bash
az webapp update \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --https-only true
```

### 4. Configure CORS

```bash
az webapp cors add \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --allowed-origins "https://yourdomain.com"
```

## Monitoring

### Enable Application Insights

```bash
# Run the monitoring configuration script
cd infrastructure/scripts
./configure-monitoring.sh <app-name>
```

Or manually:

```bash
# Create Application Insights
az monitor app-insights component create \
  --app ai-openai-apps \
  --location eastus \
  --resource-group rg-openai-apps

# Link to web app
az webapp config appsettings set \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
```

### View Logs

```bash
# Stream logs in real-time
az webapp log tail \
  --name <app-name> \
  --resource-group rg-openai-apps

# Download logs
az webapp log download \
  --name <app-name> \
  --resource-group rg-openai-apps \
  --log-file logs.zip
```

### Configure Auto-Scaling

```bash
# Run the auto-scaling configuration script
cd infrastructure/scripts
./configure-autoscaling.sh
```

## Troubleshooting

### Common Issues

#### 1. 401 Unauthorized Error

**Symptoms**: API calls fail with 401 status

**Solutions**:
- Verify API key is correct in app settings
- Check endpoint URL format
- Ensure model deployment name matches
- Verify Azure OpenAI resource has proper role assignments (if using Managed Identity)

**Test connection:**
```bash
curl -X POST "$AZURE_OPENAI_ENDPOINT/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-05-15" \
  -H "Content-Type: application/json" \
  -H "api-key: $AZURE_OPENAI_API_KEY" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

#### 2. Deployment Failures

**Check deployment logs:**
```bash
az webapp log deployment show \
  --name <app-name> \
  --resource-group rg-openai-apps
```

**Common causes:**
- Missing dependencies in requirements.txt or .csproj
- Incorrect runtime version
- Configuration errors

#### 3. Slow Response Times

**Solutions**:
- Enable Application Insights for performance analysis
- Implement caching for repeated queries
- Consider upgrading App Service Plan tier
- Use connection pooling

#### 4. Quota Exceeded

**Symptoms**: 429 (Too Many Requests) errors

**Solutions**:
- Monitor usage in Azure Portal
- Request quota increase
- Implement retry logic with exponential backoff
- Deploy additional Azure OpenAI instances for load distribution

### Getting Help

- **Azure Services**: Contact Azure Support
- **Repository Issues**: Create an issue on GitHub
- **Documentation**: See [roo.md](roo.md) for comprehensive guide
- **Lab Instructions**: Check [Instructions/Labs/](Instructions/Labs/) directory

## Next Steps

After successful deployment:

1. **Set up monitoring dashboards** in Application Insights
2. **Configure alerts** for critical metrics
3. **Implement CI/CD** with GitHub Actions
4. **Set up staging slots** for blue-green deployments
5. **Review costs** in Azure Cost Management
6. **Plan for disaster recovery** and backups

## Additional Resources

- [Main Deployment Guide (roo.md)](roo.md)
- [Infrastructure README](infrastructure/README.md)
- [Example Applications](Examples/README.md)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure OpenAI Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Semantic Kernel Documentation](https://learn.microsoft.com/semantic-kernel/)

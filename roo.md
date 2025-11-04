# Creating Multiple Web Applications on Azure App Service with Azure OpenAI

This guide explains how to deploy and manage multiple web applications on Azure App Service that integrate with Azure OpenAI services.

## Overview

Azure App Service is a fully managed platform for building, deploying, and scaling web applications. When combined with Azure OpenAI, you can create intelligent applications that leverage large language models (LLMs) for various use cases.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Azure OpenAI Service                 │
│  (Shared across all applications)                       │
└─────────────────────────────────────────────────────────┘
                        ▲
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    ┌───▼────┐     ┌───▼────┐     ┌───▼────┐
    │  App   │     │  App   │     │  App   │
    │Service │     │Service │     │Service │
    │   #1   │     │   #2   │     │   #3   │
    └────────┘     └────────┘     └────────┘
```

## Prerequisites

- **Azure Subscription**: Active Azure account
- **Azure CLI**: Installed and configured ([Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Development Environment**: 
  - For C#: .NET 6.0 or later, Visual Studio or VS Code
  - For Python: Python 3.8+, pip
- **Azure OpenAI Access**: Access granted to Azure OpenAI service
- **Git**: For version control and deployment

## Step 1: Set Up Azure OpenAI Service

### 1.1 Create Azure OpenAI Resource

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
```

### 1.2 Deploy Models

```bash
# Deploy GPT-4 model
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

### 1.3 Get API Keys and Endpoint

```bash
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

echo "Endpoint: $OPENAI_ENDPOINT"
echo "API Key: $OPENAI_KEY"
```

## Step 2: Create App Service Plan

An App Service Plan defines the compute resources for your web apps. Multiple apps can share the same plan.

```bash
APP_SERVICE_PLAN="asp-openai-apps"

# Create App Service Plan (Standard tier for production)
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku S1 \
  --is-linux
```

### App Service Plan Tiers

| Tier | Use Case | Features |
|------|----------|----------|
| **F1 (Free)** | Development/Testing | Limited compute, no custom domains |
| **B1 (Basic)** | Low-traffic apps | Custom domains, manual scaling |
| **S1 (Standard)** | Production apps | Auto-scaling, staging slots |
| **P1V2 (Premium)** | High-performance | Enhanced performance, more scaling |

## Step 3: Create Multiple Web Applications

### Option A: C# Applications

#### 3.1 Create C# Web App #1 - Chat Application

```bash
APP_NAME_1="webapp-chat-$(openssl rand -hex 4)"

# Create web app
az webapp create \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"

# Configure app settings
az webapp config appsettings set \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
```

**Sample C# Code (Program.cs):**

```csharp
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;

var builder = WebApplication.CreateBuilder(args);

// Add Semantic Kernel with Azure OpenAI
builder.Services.AddKernel()
    .AddAzureOpenAIChatCompletion(
        deploymentName: builder.Configuration["AZURE_OPENAI_DEPLOYMENT_NAME"],
        endpoint: builder.Configuration["AZURE_OPENAI_ENDPOINT"],
        apiKey: builder.Configuration["AZURE_OPENAI_API_KEY"]
    );

var app = builder.Build();

app.MapPost("/chat", async (string message, Kernel kernel) =>
{
    var chatService = kernel.GetRequiredService<IChatCompletionService>();
    var response = await chatService.GetChatMessageContentAsync(message);
    return Results.Ok(new { response = response.Content });
});

app.Run();
```

#### 3.2 Create C# Web App #2 - Document Summarizer

```bash
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
```

#### 3.3 Create C# Web App #3 - Code Assistant

```bash
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
```

### Option B: Python Applications

#### 3.1 Create Python Web App #1 - Chat Application

```bash
APP_NAME_1="webapp-py-chat-$(openssl rand -hex 4)"

az webapp create \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "PYTHON|3.11"

az webapp config appsettings set \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
```

**Sample Python Code (app.py):**

```python
import os
from flask import Flask, request, jsonify
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

app = Flask(__name__)

# Initialize Semantic Kernel
kernel = Kernel()
kernel.add_service(
    AzureChatCompletion(
        deployment_name=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
        endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY")
    )
)

@app.route('/chat', methods=['POST'])
async def chat():
    data = request.json
    message = data.get('message')
    
    chat_service = kernel.get_service(type=AzureChatCompletion)
    response = await chat_service.get_chat_message_content(message)
    
    return jsonify({'response': str(response)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

**requirements.txt:**

```txt
flask==3.0.0
semantic-kernel==1.0.0
azure-identity==1.15.0
```

#### 3.2 Create Python Web App #2 - Sentiment Analyzer

```bash
APP_NAME_2="webapp-py-sentiment-$(openssl rand -hex 4)"

az webapp create \
  --name $APP_NAME_2 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "PYTHON|3.11"

az webapp config appsettings set \
  --name $APP_NAME_2 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=$OPENAI_KEY \
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
```

## Step 4: Deploy Applications

### Method 1: Local Git Deployment

```bash
# Enable local git for app 1
az webapp deployment source config-local-git \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP

# Get deployment credentials
az webapp deployment list-publishing-credentials \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP

# In your app directory
git init
git add .
git commit -m "Initial commit"
git remote add azure <GIT_URL>
git push azure main
```

### Method 2: GitHub Actions Deployment

```bash
# Configure GitHub Actions deployment
az webapp deployment github-actions add \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --repo "<your-username>/<your-repo>" \
  --branch main \
  --login-with-github
```

### Method 3: ZIP Deployment

```bash
# Zip your application
zip -r app.zip .

# Deploy
az webapp deployment source config-zip \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --src app.zip
```

### Method 4: Container Deployment

```bash
# For containerized apps
az webapp create \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --deployment-container-image-name <your-acr>.azurecr.io/<image>:<tag>
```

## Step 5: Configuration Best Practices

### 5.1 Use Managed Identity (Recommended)

Instead of API keys, use Managed Identity for better security:

```bash
# Enable system-assigned managed identity
az webapp identity assign \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP

# Get the principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --query principalId \
  --output tsv)

# Grant access to Azure OpenAI
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Cognitive Services OpenAI User" \
  --scope /subscriptions/<subscription-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$OPENAI_NAME
```

**Updated C# Code with Managed Identity:**

```csharp
using Azure.Identity;
using Microsoft.SemanticKernel;

builder.Services.AddKernel()
    .AddAzureOpenAIChatCompletion(
        deploymentName: builder.Configuration["AZURE_OPENAI_DEPLOYMENT_NAME"],
        endpoint: builder.Configuration["AZURE_OPENAI_ENDPOINT"],
        credentials: new DefaultAzureCredential()
    );
```

### 5.2 Use Azure Key Vault

Store secrets in Azure Key Vault:

```bash
# Create Key Vault
KEY_VAULT_NAME="kv-openai-$(openssl rand -hex 4)"

az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Store OpenAI key
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "OpenAIApiKey" \
  --value $OPENAI_KEY

# Reference in App Service
az webapp config appsettings set \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=https://$KEY_VAULT_NAME.vault.azure.net/secrets/OpenAIApiKey/)"
```

### 5.3 Enable Application Insights

```bash
# Create Application Insights
APP_INSIGHTS_NAME="ai-openai-apps"

az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey \
  --output tsv)

# Configure app to use Application Insights
az webapp config appsettings set \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$INSTRUMENTATION_KEY"
```

## Step 6: Scaling Strategies

### Auto-scaling Rules

```bash
# Configure auto-scaling based on CPU
az monitor autoscale create \
  --resource-group $RESOURCE_GROUP \
  --resource $APP_SERVICE_PLAN \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-cpu \
  --min-count 1 \
  --max-count 5 \
  --count 2

# Add scale-out rule (CPU > 70%)
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-cpu \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Add scale-in rule (CPU < 30%)
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-cpu \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1
```

## Step 7: Monitoring and Troubleshooting

### View Logs

```bash
# Stream logs
az webapp log tail \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP

# Download logs
az webapp log download \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --log-file logs.zip
```

### Enable Diagnostic Settings

```bash
az monitor diagnostic-settings create \
  --name diag-webapp \
  --resource /subscriptions/<subscription-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$APP_NAME_1 \
  --logs '[{"category":"AppServiceHTTPLogs","enabled":true},{"category":"AppServiceConsoleLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]' \
  --workspace <log-analytics-workspace-id>
```

## Architecture Patterns

### Pattern 1: Shared OpenAI with Multiple Apps

**Best for:** Different applications with similar AI needs

```
Azure OpenAI (Shared) → App Service Plan → [App 1, App 2, App 3]
```

**Benefits:**
- Cost-effective
- Centralized model management
- Shared quota

### Pattern 2: Dedicated OpenAI per App

**Best for:** Applications with different model requirements or isolation needs

```
Azure OpenAI #1 → App 1
Azure OpenAI #2 → App 2
Azure OpenAI #3 → App 3
```

**Benefits:**
- Better isolation
- Independent scaling
- Separate quota management

### Pattern 3: Multi-region Deployment

**Best for:** High availability and low latency

```
Region 1: Azure OpenAI + App Service
Region 2: Azure OpenAI + App Service
Azure Front Door (Global load balancing)
```

## Cost Optimization Tips

1. **Share App Service Plans**: Host multiple low-traffic apps on the same plan
2. **Use Reserved Instances**: Save up to 55% with 1 or 3-year commitments
3. **Implement Caching**: Reduce OpenAI API calls with Redis cache
4. **Monitor Token Usage**: Track and optimize prompt/completion sizes
5. **Auto-scaling**: Scale down during off-peak hours
6. **Development/Staging Slots**: Use lower-tier plans for non-production

```bash
# Create a staging slot
az webapp deployment slot create \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --slot staging

# Swap staging to production
az webapp deployment slot swap \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --slot staging
```

## Security Checklist

- [ ] Use Managed Identity instead of API keys
- [ ] Store secrets in Azure Key Vault
- [ ] Enable HTTPS only
- [ ] Configure CORS policies
- [ ] Implement rate limiting
- [ ] Enable DDoS protection
- [ ] Use Private Endpoints for Azure OpenAI
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Implement authentication (Azure AD)

```bash
# Enforce HTTPS
az webapp update \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --https-only true

# Configure CORS
az webapp cors add \
  --name $APP_NAME_1 \
  --resource-group $RESOURCE_GROUP \
  --allowed-origins "https://yourdomain.com"
```

## Sample Project Structure

```
my-openai-apps/
├── app1-chat/
│   ├── Program.cs (C#) or app.py (Python)
│   ├── appsettings.json
│   └── requirements.txt or .csproj
├── app2-summarizer/
│   ├── Program.cs or app.py
│   ├── appsettings.json
│   └── requirements.txt or .csproj
├── app3-assistant/
│   ├── Program.cs or app.py
│   ├── appsettings.json
│   └── requirements.txt or .csproj
├── infrastructure/
│   ├── deploy.sh
│   └── bicep/ (Infrastructure as Code)
└── README.md
```

## Troubleshooting Common Issues

### Issue 1: 401 Unauthorized from Azure OpenAI

**Solution:** Verify API key and endpoint configuration

```bash
# Test OpenAI connection
curl -X POST "$OPENAI_ENDPOINT/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-05-15" \
  -H "Content-Type: application/json" \
  -H "api-key: $OPENAI_KEY" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

### Issue 2: Slow Response Times

**Solutions:**
- Enable Application Insights for performance monitoring
- Implement caching for repeated queries
- Use streaming responses for long completions
- Consider upgrading App Service Plan tier

### Issue 3: Quota Exceeded

**Solutions:**
- Monitor usage in Azure Portal
- Request quota increase
- Implement retry logic with exponential backoff
- Deploy additional OpenAI instances

## Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure OpenAI Service Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Semantic Kernel Documentation](https://learn.microsoft.com/semantic-kernel/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

## Next Steps

1. Implement authentication using Azure AD B2C
2. Add Redis cache for improved performance
3. Set up CI/CD pipelines with Azure DevOps or GitHub Actions
4. Implement comprehensive logging and monitoring
5. Create disaster recovery and backup strategies
6. Optimize costs with Azure Cost Management

## Support

For issues related to:
- **Azure Services**: Contact Azure Support
- **Code Issues**: Create an issue in this repository
- **Azure OpenAI Access**: Request access through Azure Portal

---

**License**: MIT  
**Last Updated**: 2025-11-04
```

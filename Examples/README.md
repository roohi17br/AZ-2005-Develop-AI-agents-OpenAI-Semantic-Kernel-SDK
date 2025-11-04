# Example Web Applications

This directory contains example web applications that demonstrate how to integrate Azure OpenAI with Semantic Kernel in web environments, as described in [roo.md](../roo.md).

## Applications

### 1. ChatApp (C#)

A minimal ASP.NET Core web application that provides a chat endpoint powered by Azure OpenAI.

**Location**: `WebApps/ChatApp/`

**Features**:
- REST API endpoint for chat interactions
- Integration with Azure OpenAI via Semantic Kernel
- Configured for Azure App Service deployment

**Run Locally**:
```bash
cd WebApps/ChatApp
dotnet restore
dotnet run
```

**Test the API**:
```bash
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

### 2. PythonChatApp (Python)

A Flask-based web application that provides chat functionality using Azure OpenAI.

**Location**: `WebApps/PythonChatApp/`

**Features**:
- Flask REST API
- Async support for Azure OpenAI calls
- Environment variable configuration

**Run Locally**:
```bash
cd WebApps/PythonChatApp
pip install -r requirements.txt

# Set environment variables
export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
export AZURE_OPENAI_ENDPOINT="https://your-endpoint.openai.azure.com/"
export AZURE_OPENAI_API_KEY="your-api-key"

python app.py
```

**Test the API**:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

## Configuration

All applications use the same environment variable naming convention:

- `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI service endpoint
- `AZURE_OPENAI_API_KEY`: Your Azure OpenAI API key
- `AZURE_OPENAI_DEPLOYMENT_NAME`: The model deployment name (e.g., "gpt-35-turbo" or "gpt-4")

### For C# Applications

Update `appsettings.json`:
```json
{
  "AZURE_OPENAI_DEPLOYMENT_NAME": "gpt-35-turbo",
  "AZURE_OPENAI_ENDPOINT": "https://your-endpoint.openai.azure.com/",
  "AZURE_OPENAI_API_KEY": "your-api-key-here"
}
```

### For Python Applications

Create a `.env` file or set environment variables:
```bash
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo
AZURE_OPENAI_ENDPOINT=https://your-endpoint.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key-here
```

## Deployment to Azure App Service

### Option 1: Using Azure CLI

```bash
# Navigate to your app directory
cd WebApps/ChatApp

# Create a zip file
zip -r app.zip .

# Deploy to App Service
az webapp deployment source config-zip \
  --name <your-app-name> \
  --resource-group rg-openai-apps \
  --src app.zip
```

### Option 2: Using Git

```bash
# In your app directory
git init
git add .
git commit -m "Initial commit"

# Get deployment URL from Azure
az webapp deployment source config-local-git \
  --name <your-app-name> \
  --resource-group rg-openai-apps

# Push to Azure
git remote add azure <git-url>
git push azure main
```

### Option 3: Using GitHub Actions

1. Fork or push this repository to GitHub
2. Configure GitHub Actions deployment:

```bash
az webapp deployment github-actions add \
  --name <your-app-name> \
  --resource-group rg-openai-apps \
  --repo "<your-username>/<your-repo>" \
  --branch main \
  --login-with-github
```

## Enhanced Security with Managed Identity

For production deployments, use Managed Identity instead of API keys:

### Update C# Code

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

### Update Python Code

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

### Enable Managed Identity

```bash
# Enable system-assigned managed identity
az webapp identity assign \
  --name <your-app-name> \
  --resource-group rg-openai-apps

# Grant access to Azure OpenAI
az role assignment create \
  --assignee <principal-id> \
  --role "Cognitive Services OpenAI User" \
  --scope <openai-resource-id>
```

## Monitoring and Logging

### Enable Application Insights

```bash
# Add Application Insights to your app
az webapp config appsettings set \
  --name <your-app-name> \
  --resource-group rg-openai-apps \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
```

### View Logs

```bash
# Stream logs in real-time
az webapp log tail \
  --name <your-app-name> \
  --resource-group rg-openai-apps
```

## Architecture Patterns

These examples demonstrate the **Shared OpenAI with Multiple Apps** pattern from roo.md:

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
    │  Chat  │     │Summary │     │  Code  │
    │  App   │     │  App   │     │ Assist │
    └────────┘     └────────┘     └────────┘
```

## Additional Resources

- [Main Deployment Guide](../roo.md)
- [Infrastructure Scripts](../infrastructure/)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Semantic Kernel Documentation](https://learn.microsoft.com/semantic-kernel/)

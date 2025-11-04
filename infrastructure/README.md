# Infrastructure as Code

This directory contains infrastructure deployment scripts and templates for deploying Azure OpenAI and App Service applications as described in the [main deployment guide](../roo.md).

## Directory Structure

```
infrastructure/
├── scripts/          # Bash deployment scripts
│   ├── deploy-azure-openai.sh      # Deploy Azure OpenAI service
│   ├── deploy-app-services.sh      # Deploy App Service web apps
│   └── configure-security.sh       # Configure Managed Identity and Key Vault
└── bicep/           # Infrastructure as Code templates
    └── main.bicep                   # Complete infrastructure deployment
```

## Quick Start

### Prerequisites

- Azure CLI installed and configured
- Active Azure subscription
- Appropriate permissions to create resources

### Option 1: Using Bash Scripts

1. **Deploy Azure OpenAI Service:**
   ```bash
   cd scripts
   chmod +x deploy-azure-openai.sh
   ./deploy-azure-openai.sh
   ```
   
   Save the endpoint and API key from the output.

2. **Deploy App Services:**
   ```bash
   export OPENAI_ENDPOINT="<your-endpoint>"
   export OPENAI_KEY="<your-api-key>"
   
   chmod +x deploy-app-services.sh
   ./deploy-app-services.sh
   ```

3. **Configure Security (Optional but Recommended):**
   ```bash
   chmod +x configure-security.sh
   ./configure-security.sh <APP_NAME> <OPENAI_NAME>
   ```

### Option 2: Using Bicep Template

Deploy the entire infrastructure with a single command:

```bash
cd bicep
az deployment group create \
  --resource-group rg-openai-apps \
  --template-file main.bicep
```

You can customize the deployment with parameters:

```bash
az deployment group create \
  --resource-group rg-openai-apps \
  --template-file main.bicep \
  --parameters appServicePlanSku=S1 location=eastus
```

## Deployment Methods

Once your infrastructure is set up, you can deploy your applications using various methods:

### Method 1: Local Git Deployment

```bash
# Enable local git for your app
az webapp deployment source config-local-git \
  --name <APP_NAME> \
  --resource-group rg-openai-apps

# In your app directory
git init
git add .
git commit -m "Initial commit"
git remote add azure <GIT_URL>
git push azure main
```

### Method 2: GitHub Actions

```bash
az webapp deployment github-actions add \
  --name <APP_NAME> \
  --resource-group rg-openai-apps \
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
  --name <APP_NAME> \
  --resource-group rg-openai-apps \
  --src app.zip
```

## Configuration

### Environment Variables

All applications are configured with the following environment variables:

- `AZURE_OPENAI_ENDPOINT`: Azure OpenAI service endpoint
- `AZURE_OPENAI_API_KEY`: Azure OpenAI API key
- `AZURE_OPENAI_DEPLOYMENT_NAME`: Model deployment name (gpt-35-turbo or gpt-4)

### Security Best Practices

The `configure-security.sh` script implements the following security practices:

1. **Managed Identity**: Enables system-assigned managed identity for the web app
2. **Key Vault**: Stores secrets in Azure Key Vault
3. **HTTPS**: Enforces HTTPS-only connections
4. **RBAC**: Grants appropriate role assignments for Azure OpenAI access

## Monitoring

Enable Application Insights for comprehensive monitoring:

```bash
# Create Application Insights
az monitor app-insights component create \
  --app ai-openai-apps \
  --location eastus \
  --resource-group rg-openai-apps

# Configure app to use Application Insights
az webapp config appsettings set \
  --name <APP_NAME> \
  --resource-group rg-openai-apps \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
```

## Scaling

Configure auto-scaling based on CPU usage:

```bash
az monitor autoscale create \
  --resource-group rg-openai-apps \
  --resource asp-openai-apps \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-cpu \
  --min-count 1 \
  --max-count 5 \
  --count 2
```

## Troubleshooting

### View Logs

```bash
# Stream logs
az webapp log tail \
  --name <APP_NAME> \
  --resource-group rg-openai-apps

# Download logs
az webapp log download \
  --name <APP_NAME> \
  --resource-group rg-openai-apps \
  --log-file logs.zip
```

### Common Issues

1. **401 Unauthorized**: Verify API key and endpoint in app settings
2. **Deployment Failures**: Check deployment logs in Azure Portal
3. **Connection Issues**: Verify network security settings

## Cost Optimization

- **Share App Service Plans**: Multiple apps can run on the same plan
- **Use Reserved Instances**: Save up to 55% with 1 or 3-year commitments
- **Monitor Usage**: Use Azure Cost Management to track spending
- **Scale Down**: Reduce instances during off-peak hours

## Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure OpenAI Service Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Main Deployment Guide](../roo.md)

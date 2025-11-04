// Bicep template for deploying Azure OpenAI and App Service
// Based on the architecture in roo.md

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure OpenAI service')
param openAIName string = 'openai-${uniqueString(resourceGroup().id)}'

@description('Name of the App Service Plan')
param appServicePlanName string = 'asp-openai-apps'

@description('SKU for App Service Plan')
@allowed([
  'F1'
  'B1'
  'S1'
  'P1V2'
])
param appServicePlanSku string = 'S1'

@description('Names for the web applications')
param webAppNames array = [
  'webapp-chat-${uniqueString(resourceGroup().id)}'
  'webapp-summarizer-${uniqueString(resourceGroup().id)}'
  'webapp-codeassist-${uniqueString(resourceGroup().id)}'
]

// Azure OpenAI Service
resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAIName
    publicNetworkAccess: 'Enabled'
  }
}

// Deploy GPT-35-turbo model
resource gpt35Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAI
  name: 'gpt-35-turbo'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
  }
}

// Deploy GPT-4 model
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAI
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
  dependsOn: [
    gpt35Deployment
  ]
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

// Web Applications
resource webApps 'Microsoft.Web/sites@2022-09-01' = [for (appName, i) in webAppNames: {
  name: appName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNET|8.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAI.properties.endpoint
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: openAI.listKeys().key1
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT_NAME'
          value: i == 0 ? 'gpt-35-turbo' : 'gpt-4'
        }
      ]
    }
    httpsOnly: true
  }
}]

// Role assignment for Managed Identity to access Azure OpenAI
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (appName, i) in webAppNames: {
  name: guid(resourceGroup().id, appName, 'Cognitive Services OpenAI User')
  scope: openAI
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: webApps[i].identity.principalId
    principalType: 'ServicePrincipal'
  }
}]

// Outputs
output openAIEndpoint string = openAI.properties.endpoint
output openAIName string = openAI.name
output webAppUrls array = [for (appName, i) in webAppNames: {
  name: appName
  url: 'https://${webApps[i].properties.defaultHostName}'
}]

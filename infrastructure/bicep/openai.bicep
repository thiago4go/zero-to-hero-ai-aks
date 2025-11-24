param location string
param openaiName string
param deploymentName string = 'gpt-4o-mini'
param modelName string = 'gpt-4o-mini'
param modelVersion string = '2024-07-18'
param skuCapacity int = 10

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openaiName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openaiName
    publicNetworkAccess: 'Enabled'
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openai
  name: deploymentName
  sku: {
    name: 'Standard'
    capacity: skuCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}

output endpoint string = openai.properties.endpoint
output openaiName string = openai.name
output deploymentName string = deployment.name
output openaiId string = openai.id

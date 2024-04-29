targetScope = 'resourceGroup'

param appName string
param location string
// param storageAccountName string
param storageAccountConnectionString string //TODO: remove when possible
param applicationInsightInstrumentationKey string
param farmId string

param netFrameworkVersion string = 'v8.0'
param use32BitWorkerProcess bool = false

param alwaysOn bool = true

var version = '~4'
var runtime = 'dotnet-isolated'

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: farmId
    reserved: true
    siteConfig: {
      //      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      alwaysOn: alwaysOn
      vnetRouteAllEnabled: true
      netFrameworkVersion: netFrameworkVersion
      use32BitWorkerProcess: use32BitWorkerProcess
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(appName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: version
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightInstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }

        {
          name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
          value: '1'
        }
      ]
    }
  }
}

output systemPrincipalId string = functionApp.identity.principalId

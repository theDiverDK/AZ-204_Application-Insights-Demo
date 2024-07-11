targetScope = 'resourceGroup'

param appName string
param location string
param storageAccountName string
param storageAccountConnectionString string //TODO: remove when possible
param applicationInsightInstrumentationKey string
param applicationInsightConnectionString string
param farmId string

param netFrameworkVersion string = 'v8.0'
param use32BitWorkerProcess bool = false

param alwaysOn bool = true

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  kind: 'web'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: farmId
    siteConfig: {
      // linuxFxVersion: 'DOTNET|8.0'
      alwaysOn: alwaysOn
      vnetRouteAllEnabled: true
      netFrameworkVersion: netFrameworkVersion
      use32BitWorkerProcess: use32BitWorkerProcess
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'Website__StorageAccountConnectionString'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(appName)
        }

        //The following 4 are needed to have Application Insight being enabled, and shown as such in the Portal
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2' // ~3 if linux
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
    }
  }
}

output systemPrincipalId string = webApp.identity.principalId

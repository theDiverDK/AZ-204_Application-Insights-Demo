targetScope = 'resourceGroup'

param appName string
param location string
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
    }
  }
}

output systemPrincipalId string = webApp.identity.principalId

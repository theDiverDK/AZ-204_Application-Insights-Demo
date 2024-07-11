param webAppName string
//param resourceGroupName string
param appSettings object

resource webApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: webAppName
}

resource appSettingsResource 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'appsettings'
  properties: appSettings
}

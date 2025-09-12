targetScope = 'resourceGroup'

param appName string
param env string
param location string = resourceGroup().location
param availabilityTestEnabled bool = true

//Log Analytic Workspace
var logAnalyticName = '${appName}-${env}-log'
module workspace 'logAnalytics.bicep' = {
  name: 'workspace'
  params: {
    location: location
    logAnalyticsName: logAnalyticName
  }
}

//App insight
var appInsightName = '${appName}-${env}-appi'
module appInsight 'appInsight.bicep' = {
  name: 'appInsight'
  params: {
    appInsightName: appInsightName
    location: location
    workspaceid: workspace.outputs.id
  }
}

//Storage Account
var storageAccountName = toLower('${appName}${env}st')
module storageAccount 'storageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

// Key Vault for secrets
var keyVaultName = '${appName}-${env}-kv'
module keyVault 'keyVault.bicep' = {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    location: location
  }
}

//Group Alert
var availabilityTestActionGroupName = 'availabilityTestActionGroup'
module availabilityTestActionGroup 'actionGroup.bicep' = {
  name: availabilityTestActionGroupName
  params: {
    actionGroupEmail: 'soren@reinke.dk'
    actionGroupName: 'availability test alert'
    actionGroupShortName: 'avail. test'
  }
}

//Plan
var planName = '${appName}-${env}-plan'
module plan 'appServicePlan.bicep' = {
  name: 'plan'
  params: {
    location: location
    planName: planName
  }
}

//Web App
var webAppName = '${appName}-${env}-app'
module webApp 'webApp.bicep' = {
  name: webAppName
  params: {
    appName: webAppName
    farmId: plan.outputs.id
    location: location
  }
}

//Web App
var webAppName2 = 'appinsight-${env}-app'
module webApp2 'webApp.bicep' = {
  name: webAppName2
  params: {
    appName: webAppName2
    farmId: plan.outputs.id
    location: location
  }
}

//Availability Test
var availabilityTestName = 'availabilityTest'
module availabilityTest 'availabilityTest.bicep' = {
  name: availabilityTestName
  params: {
    availabilityTestName: availabilityTestName
    applicationInsightId: appInsight.outputs.applicationInsightId
    location: location
    availabilityTestUrl: '${webAppName}.azurewebsites.net' //works since we dont use custom domains.
    enabled: availabilityTestEnabled
  }
}

//Ping alert rule
var pingAlertRuleName = 'pingAlert'
module pingAlertRule 'pingAlertRule.bicep' = {
  name: pingAlertRuleName
  params: {
    actionGroupId: availabilityTestActionGroup.outputs.actionGroupId
    applicationInsightId: appInsight.outputs.applicationInsightId
    availabilityTestId: availabilityTest.outputs.availabilityTestId
    pingAlertRuleName: pingAlertRuleName
  }
}

var cosmosDBName = '${appName}-${env}-cosmosdb'
var cosmosDBDatabaseName = '${appName}-${env}-database'
var cosmosDBContainerName = '${appName}-${env}-container'
module cosmosDB 'cosmosDB.bicep' = {
  name: cosmosDBName
  params: {
    location: location
    cosmosDBName: cosmosDBName
    cosmosDBDatabaseName: cosmosDBDatabaseName
    cosmosDBContainerName: cosmosDBContainerName
  }
}

var appSettings = {
  Hello: 'World'
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsight.outputs.instrumentationKey
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2' // ~3 if linux
  XDT_MicrosoftApplicationInsights_Mode: 'recommended'
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsight.outputs.appInsightConnectionString
  ConnectionStrings__StorageAccount: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.vaultUri}secrets/StorageConnectionString)'
  ConnectionStrings__CosmosDB: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.vaultUri}secrets/CosmosConnectionString)'
  Settings__StorageAccountContainerName: 'files'
  Settings__CosmosDBContainerName: cosmosDBContainerName
  Settings__CosmosDBDatabaseName: cosmosDBDatabaseName
  ASPNETCORE_ENVIRONMENT: 'Development'

}

module webAppSettings 'webAppSettings.bicep' = {
  name: '${webAppName2}-settings'
  params: {
    webAppName: webAppName2
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', webAppName2, 'appsettings'), '2023-01-01').properties
    appSettings: appSettings
  }
  dependsOn: [
    webApp2
  ]
}


output cosmosDBDatabaseName string = cosmosDB.outputs.cosmosDBDatabaseName
output cosmosDBContainerName string = cosmosDB.outputs.cosmosDBContainerName

// Sensitive outputs removed: use Key Vault or MI/RBAC for secrets

// Store secrets in Key Vault
module storageConnSecret 'keyVaultSecret.bicep' = {
  name: 'kv-StorageConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: 'StorageConnectionString'
    secretValue: storageAccount.outputs.connectionString
  }
  dependsOn: [keyVault]
}

module cosmosConnSecret 'keyVaultSecret.bicep' = {
  name: 'kv-CosmosConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: 'CosmosConnectionString'
    secretValue: cosmosDB.outputs.cosmosDBConnectionsString
  }
  dependsOn: [keyVault]
}

// Grant Web App access to Key Vault secrets via RBAC
module raKvSecretsUser 'rbac.bicep' = {
  name: 'ra-kv-secrets-user'
  params: {
    identityId: webApp2.outputs.systemPrincipalId
    roleNameGuid: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    keyVaultName: keyVaultName
  }
}

// Diagnostics: send logs/metrics to Log Analytics
resource webAppExisting 'Microsoft.Web/sites@2023-01-01' existing = {
  name: webAppName2
}

resource diagWebApp 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName2}-diag'
  scope: webAppExisting
  properties: {
    workspaceId: workspace.outputs.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [webApp2]
}

resource storageExisting 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource diagStorage 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diag'
  scope: storageExisting
  properties: {
    workspaceId: workspace.outputs.id
    logs: [
      {
        // Use category group to cover all supported storage logs
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [storageAccount]
}

// Setup three Role Assignments on the Storage Account for 
// the function app's Managed identity
// Build in roles:
// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

// module raStorageAccountContri 'rbac.bicep' = {
//   name: 'raStorageAccountContri'
//   params: {
//     identityId: functionApp.outputs.systemPrincipalId
//     roleNameGuid: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
//   }
// }

// module raStorageBlobOwner 'rbac.bicep' = {
//   name: 'raStorageBlobOwner'
//   params: {
//     identityId: functionApp.outputs.systemPrincipalId
//     roleNameGuid: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
//   }
// }

// module raStorageQueueDataCon 'rbac.bicep' = {
//   name: 'raStorageQueueDataCon'
//   params: {
//     identityId: functionApp.outputs.systemPrincipalId
//     roleNameGuid: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
//   }
// }

targetScope = 'resourceGroup'

param appName string
param env string
param location string = resourceGroup().location

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
    applicationInsightInstrumentationKey: appInsight.outputs.instrumentationKey
    applicationInsightConnectionString: appInsight.outputs.appInsightConnectionString
    location: location
    storageAccountConnectionString: storageAccount.outputs.connectionString
    storageAccountName: storageAccount.outputs.name
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

output cosmosDBEndpoint string = cosmosDB.outputs.cosmosDBEndpoint
output cosmosDBKey string = cosmosDB.outputs.cosmosDBMasterKey
output cosmosDBDatabaseName string = cosmosDB.outputs.cosmosDBDatabaseName
output cosmosDBContainerName string = cosmosDB.outputs.cosmosDBContainerName
output cosmosDBLocation string = cosmosDB.outputs.cosmosDBLocation

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

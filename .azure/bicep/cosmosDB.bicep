param location string
param cosmosDBName string 
param cosmosDBDatabaseName string
param cosmosDBContainerName string
param defaultConsistencyLevel string = 'Session'

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosDBName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosDBDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosDBAccount
  name: cosmosDBDatabaseName
  properties: {
    resource: {
      id: cosmosDBDatabaseName
    }
    options: {}
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  name: cosmosDBContainerName
  parent: cosmosDBDatabase
  properties: {
    resource: {
      id: cosmosDBContainerName
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
    options: {}
  }
}

output cosmosDBEndpoint string = cosmosDBAccount.properties.documentEndpoint
output cosmosDBMasterKey string = cosmosDBAccount.listKeys().primaryMasterKey
output cosmosDBName string = cosmosDBAccount.name
output cosmosDBDatabaseName string = cosmosDBDatabase.name
output cosmosDBContainerName string = container.name
output cosmosDBLocation string = location

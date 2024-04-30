
param cosmosDBName string 

@description('The name of the container in the database.')
param cosmosDBContainerName string

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: '${cosmosDBName}/${cosmosDBContainerName}'
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

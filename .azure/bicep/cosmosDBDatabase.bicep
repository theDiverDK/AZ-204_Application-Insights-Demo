@description('The name of the database.')
param cosmosDBName string 

@description('The name of the database.')
param cosmosDBDatabaseName string

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: '${cosmosDBName}/${cosmosDBDatabaseName}'
  properties: {
    resource: {
      id: cosmosDBDatabaseName
    }
    options: {}
  }
}


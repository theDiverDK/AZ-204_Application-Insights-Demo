targetScope = 'resourceGroup'

param appInsightName string
param location string
param workspaceid string

var kind = 'web'

resource appInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location: location
  kind: kind
  properties: {
    Application_Type: kind
    WorkspaceResourceId: workspaceid
  }
}

output instrumentationKey string = appInsight.properties.InstrumentationKey
output appInsightConnectionString string = appInsight.properties.ConnectionString
output applicationInsightId string = appInsight.id

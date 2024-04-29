targetScope = 'resourceGroup'

param logAnalyticsName string
param location string

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
}

output id string = workspace.id

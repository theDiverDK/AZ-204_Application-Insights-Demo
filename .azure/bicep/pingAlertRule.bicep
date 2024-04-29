param pingAlertRuleName string
param actionGroupId string
param availabilityTestId string
param applicationInsightId string


resource pingAlertRule 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: pingAlertRuleName
  location: 'global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    description: 'Alert for a web test'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: availabilityTestId
      componentId: applicationInsightId
      failedLocationCount: 2
    }
    enabled: true
    evaluationFrequency: 'PT1M' 
    scopes: [
      availabilityTestId
      applicationInsightId
    ]
    severity: 1
    windowSize: 'PT5M'
  }
}

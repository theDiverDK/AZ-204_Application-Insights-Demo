param availabilityTestName string
param location string
param applicationInsightId string
param availabilityTestUrl string

resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: availabilityTestName
  location: location
  kind: 'standard'
  tags: {
    'hidden-link:${applicationInsightId}': 'Resource'
  }
  properties: {
    Enabled: false //will be set to enabled, when the web app it monitors is deployed
    Frequency: 300
    Timeout: 120
    Kind: 'standard'
    RetryEnabled: true
    Locations: [
      {
        Id: 'emea-ch-zrh-edge'
      }
      {
        Id: 'emea-se-sto-edge'
      }
      {
        Id: 'emea-au-syd-edge'
      }
      {
        Id: 'us-ca-sjc-azr'
      }
      {
        Id: 'apac-hk-hkn-azr'
      }
    ]
    Request: {
      RequestUrl: 'https://${availabilityTestUrl}'
      HttpVerb: 'GET'
      ParseDependentRequests: false
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
    Name: availabilityTestName
    SyntheticMonitorId: availabilityTestName
  }
}

output availabilityTestId string = availabilityTest.id

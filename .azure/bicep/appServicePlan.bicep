targetScope = 'resourceGroup'

param planName string
param location string
param skuTier string = 'Standard'
param skuName string = 'S1'
param capacity int = 1

//Create Linux based App Service Plan
resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    reserved: false // Linux if true
  }
}

output id string = plan.id

targetScope = 'resourceGroup'

param identityId string
param roleNameGuid string
@description('Scope resource ID to assign the role on; defaults to the resource group')
param scope string = resourceGroup().id

resource role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleNameGuid
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scope, identityId, role.id)
  scope: scope
  properties: {
    principalId: identityId
    roleDefinitionId: role.id
  }
}

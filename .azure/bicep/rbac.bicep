targetScope = 'resourceGroup'

param identityId string
param roleNameGuid string
@description('Optional Key Vault name to scope the assignment to. If empty, assignment is scoped to the resource group.')
param keyVaultName string = ''

var useKeyVaultScope = keyVaultName != ''

resource role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleNameGuid
}

// Optional Key Vault scope
resource kv 'Microsoft.KeyVault/vaults@2021-10-01' existing = if (useKeyVaultScope) {
  name: keyVaultName
}

// Role assignment scoped to resource group (default)
resource roleAssignmentRg 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!useKeyVaultScope) {
  name: guid(resourceGroup().id, identityId, role.id)
  scope: resourceGroup()
  properties: {
    principalId: identityId
    roleDefinitionId: role.id
  }
}

// Role assignment scoped to Key Vault (when keyVaultName provided)
resource roleAssignmentKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (useKeyVaultScope) {
  name: guid(kv.id, identityId, role.id)
  scope: kv
  properties: {
    principalId: identityId
    roleDefinitionId: role.id
  }
}

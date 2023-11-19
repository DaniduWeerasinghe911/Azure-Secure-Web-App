@description('The name of the Front Door profile to create. This must be globally unique.')
param name string

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string

@description('Optional. Specifies the send and receive timeout on forwarding request to the origin. When timeout is reached, the request fails and returns.')
param originResponseTimeoutSeconds int = 30

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. Resource tags.')
param tags object = {}

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

resource profile 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: name
  location: 'global'
  sku: {
    name: skuName
  }
  identity: identity
  tags: tags
  properties: {
    originResponseTimeoutSeconds: originResponseTimeoutSeconds
  }
}


@description('The name of the deployed Azure Front Door Profile.')
output name string = profile.name
@description('The resource Id of the deployed Azure Front Door Profile.')
output resourceId string = profile.id
@description('The resource Id of the deployed Azure Front Door Profile.')
output profileIdentity string = profile.identity.principalId

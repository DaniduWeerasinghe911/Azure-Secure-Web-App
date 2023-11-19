//Deploy Front Door Premium

targetScope = 'subscription'

@description('Resource Group Name')
param rgName string

@description('Key Vault Resource Group Name')
param kvRgName string

@description('Key Vault Name')
param kvName string

@description('Resource Locations')
param location string = 'australiaeast'

@description('Number for of instances to deploy')
param numberOfInstances int = 1

@description('Front door profile configuration array')
param afdProfileName string

@description('Optional. Resource tags.')
param tags object = {}

@description('Custom Ce')

var index = '0'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: tags
}

module profile '../../modules/front-door/profiles.bicep' = [for i in range(0, numberOfInstances): {
  scope: rg
  name: 'deploy_${afdProfileName}_profile_${i}'
  params: {
    name: '${afdProfileName}-${(length(string(i))) < 2 ? '${index}${string(i + 1)}' : i + 1}' //profileName
    skuName: 'Premium_AzureFrontDoor'
    systemAssignedIdentity: true
    tags: tags
  }
}
]


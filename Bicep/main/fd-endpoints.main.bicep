//Deploy Front Door Premium

targetScope =  'subscription'

@description('Resource Group Name')
param rgName string = 'fdoor-rg'

@description('The name of the existing Front Door/CDN Profile.')
param profileName string = 'fdoor-dckloud'

@description('Endpoints to deploy to Front Door.')
param endpoints array

@description('Origin Groups to deploy to Front Door.')
param originGroups array

@description('Origins to deploy to Front Door.')
param origins array

@description('Optional. Secrets to deploy to Front Door. Required if customer certificates are used to secure endpoints.')
param secrets array = []

@description('Optional. Custom domains to deploy to Front Door.')
param customDomains array = []

@description('Routes to deploy to Front Door.')
param routes array

@description('Optional. RuleSets to deploy to Front Door.')
param ruleSets array = []

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: rgName
}

module fdEndpoints '../../modules/front-door/profile-endpoints.bicep' = {
  scope: rg
  name: 'deploy_frontdoor_endpoints'
  params: {
    endpoints: endpoints
    originGroups: originGroups
    origins: origins
    profileName: profileName
    routes: routes
    secrets:secrets
    customDomains:customDomains
    ruleSets:ruleSets
  }
}

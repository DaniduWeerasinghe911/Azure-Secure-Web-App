//This include application deplooymnets
//inclding webapps and Functionapps infra level
//No Code deployments

targetScope = 'subscription'

@description('Environment Location')
param location string = 'australiaeast'

@description('Resource Group Name for the deployment')
param rgName string

@description('App Service Plan Name for the deployment')
param appServicePlanName string

@description('vault webapp name')
param webAppName string

@description('Front Door header')
param frontDoorHeader string

@description('Object containing resource tags.')
param tags object = {}

@description('Identify if its a production environment')
param isProd bool = false

@description('Log analytics workspace ID')
param diagnosticLogAnalyticsId string = ''

@description('Log analytics workspace ID')
param diagnosticStorageAccountId string = ''

@description('Application Insights ID')
param diagnosticAppInsightId string = ''

@description('App Service Subnet ID')
param appServiceSubnetId string

@description('App Service Plan Configuration')
param aspConfig object


var webAppPlanName = '${appServicePlanName}-win'


var appInsightName = split(diagnosticAppInsightId, '/')[8]
var appInsightsResourceGroup = split(diagnosticAppInsightId, '/')[4]
var appInsightsSubscriptionId = split(diagnosticAppInsightId, '/')[2]


var diagSettings = {
  name: 'diag-log'
  workspaceId: diagnosticLogAnalyticsId
  storageAccountId: diagnosticStorageAccountId
  eventHubAuthorizationRuleId: ''
  eventHubName: ''
  enableLogs: true
  enableMetrics: true
  retentionPolicy: {
    days: 0
    enabled: true
  }
}

// Resource Group for networking
resource rg_webservices 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  tags: tags
  location: location
}

//App Service Plan deployment for Webapps Windows backend
module aspWeb '../modules/web/app-service-plan/app-service-plan.bicep' = {
  name: 'deployAppServicePlan'
  scope:resourceGroup(rg_webservices.name)
  params: {
    location: location
    appKind: 'windows'
    appPlanName: webAppPlanName
    skuCapacity:  aspConfig.skuCapacity
    skuName: aspConfig.skuName
    skutier: aspConfig.skutier
    diagSettings:  isProd ? diagSettings : {}
    tags: tags
  }
}

//Deploy Vault App
module vault '../modules/web/app/app-windows.bicep' = {
  name: 'deployAdminApp'
  scope:resourceGroup(rg_webservices.name)
  params: {
    location: location
    appInsightsName: appInsightName
    appName: webAppName
    serverFarmId: aspWeb.outputs.appServiceId
    diagSettings:  isProd ? diagSettings : {}
    tags: tags
    ipSecurityRestrictions: empty(frontDoorHeader) ? [] : [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 1
        name: 'Allow-FrontDoor-Only'
        headers: {
          'x-azure-fdid': [
            frontDoorHeader
          ]
        }
      }
      {
        ipAddress: 'Any'
        action: 'Deny'
        priority: 2147483647
        name: 'Deny all'
        description: 'Deny all access'
      }
    ]
    logRg:appInsightsResourceGroup
    subnetId:appServiceSubnetId
  }
}

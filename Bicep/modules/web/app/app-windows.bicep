@description('Name of web application')
param appName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('Application ')
param netFrameworkVersion string = 'v6.0'

@description('Resource Id of the server farm to host the application')
param serverFarmId string

@description('The type of Web App to create (web, api, ...)')
param webAppKind string = 'web'

@description('Use ARR Affinity.  Keep enabled if app not truely stateless.')
param clientAffinityEnabled bool = true

@description('Keeps web app as always on (hot).')
param alwaysOn bool = false

@description('Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = true

@description('Comma delimited string of allowed origins hosts.  Use * for allow-all.')
param corsAllowedOrigins string = ''

@description('True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

@description('True/False on whether to enable Support Credentials for CORS.')
param vnetRouteAllEnabled bool = false

@description('ipsecurity restrictions Array')
param ipSecurityRestrictions array

param scmIpSecurityRestrictions array = []

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
@metadata({
  name: 'Diagnostic settings name'
  workspaceId: 'Log analytics resource id'
  storageAccountId: 'Storage account resource id'
  eventHubAuthorizationRuleId: 'EventHub authorization rule id'
  eventHubName: 'EventHub name'
  enableLogs: 'Enable logs'
  enableMetrics: 'Enable metrics'
  retentionPolicy: {
    days: 'Number of days to keep data'
    enabled: 'Enable retention policy'
  }
})
param diagSettings object = {}

@description('Name of App Insights')
param appInsightsName string

@description('Name Log Resource Group')
param logRg string

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
@metadata({
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
})
param tags object = {}

var corsAllowedOrigins_var = split(corsAllowedOrigins, ',')

resource webApplication 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  tags: !empty(tags) ? tags : null
  identity:{
    type: 'SystemAssigned'
  }
  kind: webAppKind
  properties: {
    httpsOnly: true
    serverFarmId: serverFarmId
    clientAffinityEnabled: clientAffinityEnabled
    siteConfig: {
      alwaysOn: alwaysOn
      use32BitWorkerProcess: use32BitWorkerProcess
      scmIpSecurityRestrictionsUseMain: false
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      vnetRouteAllEnabled: vnetRouteAllEnabled
      cors: {
        allowedOrigins: corsAllowedOrigins_var
        supportCredentials: corsSupportCredentials
      }
      ipSecurityRestrictions : ipSecurityRestrictions
      scmIpSecurityRestrictions : []
    netFrameworkVersion: empty(netFrameworkVersion) ? json('null') : netFrameworkVersion
    }
  }
}

resource webApp_diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: webApplication
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId 
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: diagSettings.enableLogs
      }
      {
        categoryGroup: 'audit'
        enabled: diagSettings.enableLogs
      } 
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
      }
    ]
  }
}

//add app insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope:resourceGroup(subscription().subscriptionId,logRg)
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${webApplication.name}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
    ApplicationInsightsAgent_EXTENSION_VERSION:'~2'
    XDT_MicrosoftApplicationInsights_Mode:'default'
  }
  dependsOn: [
    //appServiceSiteExtension
  ]
}


// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${appName}-delete-lock'
  scope: webApplication
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

//VNET Integration

param subnetId string = ''

var vnetResourceId = first(split(subnetId,'/subnets'))

resource networkConfig 'Microsoft.Web/sites/networkConfig@2022-03-01' = if(subnetId != '') {
  parent: webApplication
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
    swiftSupported: true
  }
}

resource NetworkIntegration 'Microsoft.Web/sites/virtualNetworkConnections@2020-12-01' = {
  parent: webApplication
  name : webApplication.name
  properties: {
    vnetResourceId: vnetResourceId  //subnet //'/subscriptions/6da6ad04-e536-4124-a437-c62b91ca3cff/resourceGroups/dckloud-shd-svcs-rg/providers/Microsoft.Network/virtualNetworks/dckloud-shd-ae-vnet'
    isSwift: true
  }
}

output name string = webApplication.name
output id string = webApplication.id

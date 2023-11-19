// Function App that is used for code deployments (not docker) and VNET Integrated
// Requries an App Service Plan or Premium Function App Plan
// Function Runtime v3
// Assumes existing App Insights for monitoring
// Assumes existing storage account
// Must provide Subnet Resource ID to integrate with and assumes subnet delegation already done
// VNet intergation needs to fix

//@description('Subscription ')
//param subscriptionID string = subscription().subscriptionId

//@description('Sql server resource ID')
//param sqlserverId string ='/subscriptions/${subscriptionID}/resourceGroups/rg-primary-qa-estau-01/providers/Microsoft.Sql/servers/thrive-qa-sqlserver'

@description('Name of Function App')
param fncAppName string

@description('Location for resources to be created')
param location string = resourceGroup().location

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
  'python'
  'powershell'
])
param functionRuntime string

@description('ResourceId of Storage Account to host Function App.')
param storageAccountId string 

@description('ResourceId of Application Insights instance for Function App monitoring.')
param appInsightsId string

@description('Node.JS version. Only needed if runtime is node')
param nodeVersion string = '~12'

@description('Only applies if you using Consumption or Premium service plans.')
param preWarmedInstanceCount int = 1

@description('Resource Id of the server farm to host the function app. Needs to be an App Service Plan or Premium Plan')
param serverFarmId string

//@description('Resource Id of the subnet to host the function app')
//param subnetID string

@description('Sets 32-bit vs 64-bit worker architecture')
param use32BitWorkerProcess bool = true

@description('Array of allowed origins hosts.  Use [*] for allow-all.')
param corsAllowedOrigins array = []

@description('True/False on whether to enable Support Credentials for CORS.')
param corsSupportCredentials bool = false

//@description('ipsecurity restrictions Array')
//param ipSecurityRestrictions array

//param scmIpSecurityRestrictions array

//@description('Force all traffic to go via VNET')
//param vnetRouteAllEnabled bool = true

param functionContentShareName string = ''

@description('Enable when you are VNET integrated and need non-HTTP triggers for services inside a VNET.')
param functionsRuntimeScaleMonitoringEnabled bool = false

@description('Additional App Settings to include on top of that required for this function app')
@metadata({
  note: 'Sample input'
  addAppSettings: [
    {
      name: 'key-name'
      value: 'key-value'
    }
  ]
})
param addAppSettings array

@description('Object containing diagnostics settings. If not provided diagnostics will not be set.')
param diagSettings object = {}

@description('Enable a Can Not Delete Resource Lock. Useful for production workloads.')
param enableResourceLock bool = false

@description('Object containing resource tags.')
param tags object = {}

// Extract out names
var storageAccountName = split(storageAccountId,'/')[8]

param connectionStrings array

//param sqlServer string = 'thrive-qa-sqlserver'
//param sqldb string = 'thrive-qa-sqldb-01'

// Build base level App Settings needed for Function App
var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionRuntime
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: nodeVersion
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: reference(appInsightsId, '2020-02-02-preview').InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: 'InstrumentationKey=${reference(appInsightsId, '2020-02-02-preview').InstrumentationKey}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: functionContentShareName
  }
  {
    name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
    value:'true'
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }  
]

var appSettings = union(baseAppSettings,addAppSettings)

// Resource Definition
resource fncApp 'Microsoft.Web/sites@2021-02-01' = {
  name: fncAppName
  location: location
  tags: !empty(tags) ? tags : null
  identity:{
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    httpsOnly: true           // Security Setting
    serverFarmId: serverFarmId
    reserved: true
    //isXenon: false
    //hyperV: false
    siteConfig: {
      use32BitWorkerProcess: use32BitWorkerProcess
      http20Enabled: true     // Security Setting
      minTlsVersion: '1.2'    // Security Setting
      scmMinTlsVersion: '1.2' // Security Setting
      ftpsState: 'Disabled'   // Security Setting
      linuxFxVersion: 'PYTHON|3.9'
      numberOfWorkers: 1
      preWarmedInstanceCount: preWarmedInstanceCount
      //vnetRouteAllEnabled: vnetRouteAllEnabled
      functionsRuntimeScaleMonitoringEnabled: functionsRuntimeScaleMonitoringEnabled
      cors: {
        allowedOrigins: corsAllowedOrigins
        supportCredentials: corsSupportCredentials
      }
      appSettings: appSettings
      pythonVersion: '3.9'
      connectionStrings: connectionStrings
      //ipSecurityRestrictions : ipSecurityRestrictions
      //scmIpSecurityRestrictions : scmIpSecurityRestrictions
    }
    /*
     scmSiteAlsoStopped: false
     clientAffinityEnabled: false
     clientCertEnabled: false
     hostNamesDisabled: false
     containerSize: 1536
     dailyMemoryTimeQuota: 0
     redundancyMode: 'None'
    */
    //virtualNetworkSubnetId : subnetID
    
  }  
}

/*
//VNET Integration
resource networkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  parent: fncApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetID
    swiftSupported: true
  }
}
*/

/*
resource NetworkIntegration 'Microsoft.Web/sites/virtualNetworkConnections@2020-12-01' = {
  parent: fncApp
  name : fncApp.name
  properties: {
    vnetResourceId: '/subscriptions/6da6ad04-e536-4124-a437-c62b91ca3cff/resourceGroups/dckloud-shd-svcs-rg/providers/Microsoft.Network/virtualNetworks/dckloud-shd-ae-vnet'
    isSwift: true
  }
}*/

// Diagnostics
resource diagnostics 'Microsoft.insights/diagnosticsettings@2017-05-01-preview' = if (!empty(diagSettings)) {
  name: empty(diagSettings) ? 'dummy-value' : diagSettings.name
  scope: fncApp
  properties: {
    workspaceId: empty(diagSettings.workspaceId) ? json('null') : diagSettings.workspaceId
    storageAccountId: empty(diagSettings.storageAccountId) ? json('null') : diagSettings.storageAccountId
    eventHubAuthorizationRuleId: empty(diagSettings.eventHubAuthorizationRuleId) ? json('null') : diagSettings.eventHubAuthorizationRuleId
    eventHubName: empty(diagSettings.eventHubName) ? json('null') : diagSettings.eventHubName
    
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: diagSettings.enableLogs
        retentionPolicy: empty(diagSettings.retentionPolicy) ? json('null') : diagSettings.retentionPolicy
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

// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${fncAppName}-delete-lock'
  scope: fncApp
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = fncApp.name
output id string = fncApp.id

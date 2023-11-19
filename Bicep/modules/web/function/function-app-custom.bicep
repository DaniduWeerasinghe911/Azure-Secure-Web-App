//this function only include the app function deployment inclduing the storage accounts
//Need to update the functionApp details

//Declaring Parameters
@description('Subscription ')
param subscriptionID string 

param connectionStrings array

@description('Object containing resource tags.')
param tags object = {}

@description('First Function App Parameters')
param FunctionApp object 

//param storageAccountVnetRules array 

//param sqlServername string = 'thrive-qa-sqlserver'
//param sqlDBname string = 'thrive-qa-sqldb-01'

//Details 
param networkAclsDefaultAction string
/*
param storagePEs array = [
  {
    type: 'blob'
  }
  {
    type: 'file'
  }
  {
    type: 'queue'
  }
  {
    type: 'table'
  }
]
*/
param diagSettings object

/*sql connection object
param sqlConnString object = {
      name: 'SQLBaaSString'
      value: 'Server=tcp:${sqlServername}.database.windows.net,1433;Database=${sqlDBname};MultipleActiveResultSets=true'
      type: 'SQLServer'
     }*/

//Define Variable
 var storageAccountName = toLower(replace(FunctionApp.fncAppName,'-',''))
 var functionContentShareName = 'function-content-share'
 
//Deploy a Function App
////Storage for the function App
module storageAccountforFunction '../../storage/storage.bicep'= {
  name: 'DeployStorageAccountFunction-${storageAccountName}'
  params: {
    storageAccountName: storageAccountName
    storageSku: 'Standard_LRS'
    //virtualNetworkRules:storageAccountVnetRules
    networkAclsDefaultAction: networkAclsDefaultAction
    diagSettings:diagSettings
    blobContainers:[]
  }
}

resource functionContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  dependsOn:[
    storageAccountforFunction
  ]
  name: '${storageAccountName}/default/${functionContentShareName}'
}
/*
module storageAccountPE '../../storage/storage-PE.bicep' = [for storagePE in storagePEs: {
  name: 'DeployStorageAccountPE${storageAccountName}${storagePE.type}'
  params: {
    dnsZoneResourceGroup: resourceGroup().name
    dnsZoneSubscriptionId: subscriptionID
    id: '/subscriptions/${subscriptionID}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}'
    resourceName: storageAccountName
    subnetId: FunctionApp.DataSubnetID
    type: storagePE.type
  }
  dependsOn: [
    storageAccountforFunction
  ]
}]

*/
resource serverFarm 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: 'ásp-${FunctionApp.fncAppName}'
  location: resourceGroup().location
  properties: {
    reserved: false
  }
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
  kind: 'windows'
}

////Function App
module functionApp '../../web/function/function-app-vnet-integrated.bicep' = {
  name: 'DeployFunction-${FunctionApp.fncAppName}'
  params: {
    appInsightsId: FunctionApp.appInsightID
    fncAppName: FunctionApp.fncAppName
    functionRuntime: FunctionApp.functionRuntime
    serverFarmId: serverFarm.id
    //subnetID : FunctionApp.subnetID
    storageAccountId:'/subscriptions/${subscriptionID}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}'
    diagSettings:diagSettings
    addAppSettings :FunctionApp.addAppSettings
    ipSecurityRestrictions :FunctionApp.ipSecurityRestrictions
    //scmIpSecurityRestrictions : FunctionApp.scmIpSecurityRestrictions
    //vnetResourceId: vnetResourceID
    connectionStrings:connectionStrings
    functionContentShareName:functionContentShareName
  }
  dependsOn: [
    storageAccountforFunction
    functionContentShare
   // storageAccountPE
  ]
}

//this function only include the app function deployment inclduing the storage accounts
//Need to update the functionApp details

//Declaring Parameters
@description('Subscription ')
param subscriptionID string 
param location string =resourceGroup().location
 
@description('Object containing resource tags.')
param tags object = {}

@description('First Function App Parameters')
param FunctionApp object 

//param storageAccountVnetRules array 

param connectionStrings array


//Details 
param networkAclsDefaultAction string
/*
@description('DNS Zone Resource Group')
param dnsZoneResourceGroup string = resourceGroup().name

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


//Define Variable
 var storageAccountName1 = toLower(replace(FunctionApp.fncAppName,'-',''))
 var functionContentShareName = 'function-content-share'
 var storageAccountName = ((length(storageAccountName1)>23) ? substring(storageAccountName1,0,23): storageAccountName1)
    
//Deploy a Function App
////Storage for the function App
module storageAccountforLinuxFunction '../../storage/storage.bicep'= {
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
    storageAccountforLinuxFunction
  ]
  name: '${storageAccountName}/default/${functionContentShareName}'
}
/*
module storageAccountPE '../../storage/storage-PE.bicep' = [for storagePE in storagePEs: {
  name: 'DeployStorageAccountPE${storageAccountName}${storagePE.type}'
  params: {
    dnsZoneResourceGroup: dnsZoneResourceGroup
    dnsZoneSubscriptionId: subscriptionID
    id: '/subscriptions/${subscriptionID}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}'
    resourceName: storageAccountName
    subnetId: FunctionApp.DataSubnetID
    type: storagePE.type
  }
  dependsOn: [
    storageAccountforLinuxFunction
  ]
}]
*/


resource serverFarm 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: 'ásp-${FunctionApp.fncAppName}'
  location: location
  //location:resourceGroup().location
  properties: {
    reserved: true
  }
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
  kind: 'linux'
}

////Function App
module functionApp '../../web/function/function-app-vnet-integrated-linux.bicep' = {
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
    //ipSecurityRestrictions :FunctionApp.ipSecurityRestrictions
    //scmIpSecurityRestrictions : FunctionApp.scmIpSecurityRestrictions
    //vnetResourceId: vnetResourceID
    connectionStrings:connectionStrings
    functionContentShareName:functionContentShareName
  }
  dependsOn: [
    storageAccountforLinuxFunction
    serverFarm
    functionContentShare
    //storageAccountPE
  ]
}

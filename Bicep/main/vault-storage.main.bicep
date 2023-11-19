
targetScope = 'subscription'

@description('The RgName name.')
param rgName string

@description('The resource name.')
param sqlServerName string

@description('The DNS Zone Resource Group.')
param dnsZoneResourceGroup string

@description('The dns Zone Subscription Id')
param dnsZoneSubscriptionId string

@description('The geo-location where the resource lives.')
param location string

@description('Optional. Resource tags.')
param tags object = {}


@description('Private Endpoint Subnet ID')
param subnetId string = ''


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: tags
}

module sqlServer '../modules/sql/azure-sql-server.bicep' = {
  name: 'deploy_azure_sqlserver'
  scope: rg
  params: {
    location: location
    aadAdminLogin:''
    aadAdminObjectId:''
    sqlAdminLogin:'${sqlServerName}-admin'
    sqlAdminPassword:'abcd1234!@#$'
    sqlServerName:sqlServerName
  }
}

module sqlServerPe '../modules/sql/azure-sql-server-PE.bicep' = {
  scope: rg
  name: 'deploy_azure_sqlserver_pe'
  params: {
    location: location
    subnetId: subnetId
    dnsZoneResourceGroup:dnsZoneResourceGroup
    dnsZoneSubscriptionId:dnsZoneSubscriptionId
    id:sqlServer.outputs.id
    resourceName:sqlServer.outputs.name
  }
}

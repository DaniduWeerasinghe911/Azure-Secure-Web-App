// Bicep template to deploy an Application Service Environment

@description('Location of the resource.')
param location string = resourceGroup().location

@description('The name of the resource.')
param aseName string

@description('Internal Load Balancing Mode - None turns it off (for public ASE), Web,Publishing allows content to be uploaded as well as served from the ASE')
@allowed([
  'None'
  'Publishing'
  'Web'
  'Web, Publishing'
])
param internalLoadBalancingMode string = 'Web, Publishing'

@description('The version of the ASE to deploy (ASEV2 or ASEV3)')
@allowed([
  'ASEV2'
  'ASEV3'
])
param kind string

@description('The VNet ID to create the ASE in')
param virtualNetworkid string

@description('The subnet name to create the ASE in')
param subnetName string

// Resource Definition
resource hostingEnvironment 'Microsoft.Web/hostingEnvironments@2022-09-01' = {
  name: aseName
  location: location
  kind: kind
  properties: {
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: virtualNetworkid
      subnet: subnetName
    }
  }
}

// Output id and name as a standard to allow module referencing.
output id string = hostingEnvironment.id
output name string = hostingEnvironment.name

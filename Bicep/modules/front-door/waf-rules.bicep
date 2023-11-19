@description('The resource name.')
param name string

@description('The sku of the Front Door firewall policy.')
@allowed([
  'Classic_AzureFrontDoor'
  'Premium_AzureFrontDoor'
  'Standard_AzureFrontDoor'
])
param skuName string

@description('Optional. Resource tags.')
@metadata({
  doc: 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#arm-templates'
  example: {
    tagKey: 'string'
  }
})
param tags object = {}

@description('Optional. Firewall policy settings.')
@metadata({
  doc: 'https://learn.microsoft.com/en-us/azure/templates/microsoft.network/frontdoorwebapplicationfirewallpolicies?pivots=deployment-language-bicep#policysettings'
  example: {
    customBlockResponseBody: ''
    customBlockResponseStatusCode: ''
    redirectUrl: ''
    requestBodyCheck: 'Whether allow WAF to check request Body. Acceptable values are "Enabled" or "Disabled".'
    enabledState: 'The state of the policy. Acceptable values are "Enabled" or "Disabled".'
    mode: 'The mode of the policy. Acceptable values are "Detection" or "Prevention".'
  }
})
param policySettings object = {
  requestBodyCheck: 'Enabled'
  enabledState: 'Enabled'
  mode: 'Detection'
}

@description('Optional. The custom rules inside the policy.')
@metadata({
  doc: 'https://learn.microsoft.com/en-us/azure/templates/microsoft.network/frontdoorwebapplicationfirewallpolicies?pivots=deployment-language-bicep#customrulelist'
  example: {
    rules: [
      {
        action: 'Allow'
        matchConditions: [
          {
            matchValue: [
              '172.1.15.2/24'
            ]
            negateCondition: false
            transforms: []
            matchVariable: 'RemoteAddr'
            operator: 'IPMatch'
          }
        ]
        priority: 10
        ruleType: 'MatchRule'
        enabledState: 'Enabled'
        name: 'ipwhitelist'
      }
    ]
  }
})
param customRules object = {}

@description('Optional. The Exclusions that are applied on the policy.')
@metadata({
  doc: 'https://learn.microsoft.com/en-us/azure/templates/microsoft.network/frontdoorwebapplicationfirewallpolicies?pivots=deployment-language-bicep#managedrulesetlist'
  example: {
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          exclusions: [
            {
              matchVariable: 'RequestHeaderNames'
              selector: 'okta'
              selectorMatchOperator: 'Contains'
            }
          ]
          ruleGroupOverrides: [
            {
              ruleGroupName: 'The managed rule group to override'
              exclusions: [
                {
                  matchVariable: 'RequestHeaderNames'
                  selector: 'string'
                  selectorMatchOperator: 'Contains'
                }
              ]
              rules: [
                {
                  ruleId: 'Identifier for the managed rule'
                  action: 'Block'
                  enabledState: 'Enabled'
                  exclusions: [
                    {
                      matchVariable: 'RequestHeaderNames'
                      selector: 'string'
                      selectorMatchOperator: 'Contains'
                    }
                  ]
                }
              ]
            }
          ]
          ruleSetAction: 'Block'
        }
      ]
    }
  }
})
param managedRules object = {}

@description('Optional. Specify the type of resource lock.')
@allowed([
  'NotSpecified'
  'ReadOnly'
  'CanNotDelete'
])
param resourceLock string = 'NotSpecified'

var lockName = toLower('${firewallPolicy.name}-${resourceLock}-lck')

resource firewallPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: name
  location: 'global'
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    customRules: customRules
    managedRules: managedRules
    policySettings: policySettings
  }
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourceLock != 'NotSpecified') {
  scope: firewallPolicy
  name: lockName
  properties: {
    level: resourceLock
    notes: (resourceLock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
}

@description('The name of the deployed firewall policy.')
output name string = firewallPolicy.name

@description('The resource ID of the deployed firewall policy.')
output resourceId string = firewallPolicy.id

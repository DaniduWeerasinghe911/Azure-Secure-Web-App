@description('The name of the existing Front Door/CDN Profile.')
param profileName string

@description('The name of the existing Front Door/CDN Profile RuleSet.')
param rulesetName string

@description('The rules to apply to the RuleSet.')
param rules array

resource ruleset 'Microsoft.Cdn/profiles/ruleSets@2022-11-01-preview' existing = {
  name: '${profileName}/${rulesetName}'
}

resource rule 'Microsoft.Cdn/profiles/ruleSets/rules@2022-11-01-preview' = [for r in rules: {
  name: r.ruleName
  parent: ruleset
  properties: {
    actions: r.actions
    conditions: r.conditions
    matchProcessingBehavior: r.matchProcessingBehavior
    order: r.order
  }
}]

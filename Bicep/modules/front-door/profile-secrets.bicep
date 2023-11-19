@description('The name of the existing Front Door/CDN Profile.')
param profileName string

@description('Optional. Secrets to deploy to Front Door. Required if customer certificates are used to secure endpoints.')
@metadata({
  doclink: 'https://learn.microsoft.com/en-us/azure/templates/microsoft.cdn/profiles/secrets?pivots=deployment-language-bicep'
  example: {
    secretName: 'secret1'
    parameters: {
      type: 'CustomerCertificate'
      certificateSecretId: 'secret resource id to secret in key vault containing certificate'
    }
  }
})
param secrets array = []

resource profile 'Microsoft.Cdn/profiles@2022-11-01-preview' existing = {
  name: profileName
}


resource secret 'Microsoft.Cdn/profiles/secrets@2022-11-01-preview' = [for s in secrets: {
  parent: profile
  name: s.secretName
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      useLatestVersion: true
      secretSource: {
        id: s.parameters.certificateSecretId
      }
    }
  }
}]


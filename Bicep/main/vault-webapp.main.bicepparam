using './vault-webapp.main.bicep'

param location = 'australiaeast'
param rgName = ''
param appServicePlanName = ''
param webAppName = ''
param frontDoorHeader = ''
param tags = {}
param isProd = false
param diagnosticLogAnalyticsId = ''
param diagnosticStorageAccountId = ''
param diagnosticAppInsightId = ''
param appServiceSubnetId = ''
param aspConfig = {}


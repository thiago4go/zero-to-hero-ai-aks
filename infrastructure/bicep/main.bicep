targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = resourceGroup().location

@description('AKS cluster name')
param aksClusterName string

@description('PostgreSQL server name')
param postgresqlServerName string

@description('PostgreSQL admin password')
@secure()
param postgresqlAdminPassword string

@description('Log Analytics workspace name')
param logAnalyticsName string

// Log Analytics Workspace
module monitoring 'monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
  }
}

// AKS Cluster
module aks 'aks.bicep' = {
  name: 'aks-deployment'
  params: {
    location: location
    aksClusterName: aksClusterName
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  }
}

// PostgreSQL Flexible Server
module postgresql 'postgresql.bicep' = {
  name: 'postgresql-deployment'
  params: {
    location: location
    serverName: postgresqlServerName
    administratorLoginPassword: postgresqlAdminPassword
  }
}

output aksClusterName string = aks.outputs.clusterName
output postgresqlServerFqdn string = postgresql.outputs.serverFqdn
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId

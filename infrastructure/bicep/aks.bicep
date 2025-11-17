@description('Location for AKS cluster')
param location string

@description('AKS cluster name')
param aksClusterName string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: aksClusterName
  location: location
  tags: {
    lab: 'ai-aks'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 2
        vmSize: 'Standard_DC2s_v3'
        mode: 'System'
        osType: 'Linux'
        enableAutoScaling: false
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      loadBalancerSku: 'standard'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
  }
}

resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'dapr'
  scope: aks
  properties: {
    extensionType: 'microsoft.dapr'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
  }
}

output clusterName string = aks.name
output clusterFqdn string = aks.properties.fqdn

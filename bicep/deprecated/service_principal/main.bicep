param location string = resourceGroup().location
param aksName string = 'aks-${uniqueString(resourceGroup().id)}'
param kubernetesVersion string = '1.27.7'
param servicePrincipalId string
@secure()
param servicePrincipalSecret string
param nodeCount int = 1
param nodeVmSize string = 'Standard_D2s_v3'
@allowed([
  'NodeImage'
  'None'
  'SecurityPatch'
  'Unmanaged'
])
param nodeOSUpgradeChannel string = 'NodeImage'
@allowed([
  'node-image'
  'none'
  'patch'
  'rapid'
  'stable'
])
param upgradeChannel string = 'patch'
param laName string = 'la-${uniqueString(resourceGroup().id)}'
param tags object = {
}

var defaultPoolname = 'agentpool'

resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: laName
  location: location
  tags: tags
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-09-01' = {
  name: aksName
  location: location
  tags: union(tags, {
    network: 'kubenet'
    nodeOSUpgradeChannel: nodeOSUpgradeChannel
    upgradeChannel: upgradeChannel
  })
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    agentPoolProfiles: [
      {
        name: defaultPoolname
        count: nodeCount
        mode: 'System'
        vmSize: nodeVmSize
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
      }
    ]
    kubernetesVersion: kubernetesVersion
    dnsPrefix: aksName
    networkProfile: {
      loadBalancerSku: 'Standard'
      networkPlugin: 'kubenet'
    }
    autoUpgradeProfile: {
      nodeOSUpgradeChannel: nodeOSUpgradeChannel
      upgradeChannel: upgradeChannel
    }
    servicePrincipalProfile: {
      clientId: servicePrincipalId
      secret: servicePrincipalSecret
    }
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: la.id
        }
        enabled: true
      }
    }
  }
}

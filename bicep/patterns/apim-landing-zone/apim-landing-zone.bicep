targetScope = 'subscription'
//APIM

param location string

param networkResourceGroupName string

param apimResourceGroupName string

// added a conditional parameter to deploy the network watcher to cater for deployment scenarios in the same subscription
param deployNetworkWatcher bool = false

param networkWatcherName string = ''

param logAnalyticsWorkspaceName string

param hubLogAnalyticsWorkspaceId string

param hubVirtualNetworkId string

param apimNsgName string

param apimNsgRules array

param apimRouteTableName string

param apimRoutes array

param virtualNetworkName string

param virtualNetworkSettings object

var diagsSuffix = 'diags'

module networkResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'networkResourceGroup-${uniqueString(deployment().name, location, networkResourceGroupName)}'
  params: {
    name: networkResourceGroupName
    location: location
  }
}

module apimResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'apimResourceGroup-${uniqueString(deployment().name, location, apimResourceGroupName)}'
  params: {
    name: apimResourceGroupName
    location: location
  }
}

module networkWatcher 'br/public:avm/res/network/network-watcher:0.3.0' = if (deployNetworkWatcher) {
  dependsOn: [networkResourceGroup]
  scope: resourceGroup(networkResourceGroupName)
  name: 'networkWatcher-${uniqueString(deployment().name, location, networkWatcherName)}'
  params: {
    name: networkWatcherName
    location: location
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  dependsOn: [apimResourceGroup]
  scope: resourceGroup(apimResourceGroupName)
  name: 'logAnalyticsWorkspace-${uniqueString(deployment().name, location, logAnalyticsWorkspaceName)}'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    skuName: 'PerGB2018'
  }
}

module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = {
  dependsOn: [networkResourceGroup]
  scope: resourceGroup(networkResourceGroupName)
  name: 'networkSecurityGroup-${uniqueString(deployment().name, location, apimNsgName)}'
  params: {
    name: apimNsgName
    location: location
    securityRules: apimNsgRules
    diagnosticSettings: [
      {
        name: '${apimNsgName}-${diagsSuffix}'
        workspaceResourceId: hubLogAnalyticsWorkspaceId
      }
    ]
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.4.0' = {
  dependsOn: [networkResourceGroup]
  scope: resourceGroup(networkResourceGroupName)
  name: 'routeTable-${uniqueString(deployment().name, location, apimRouteTableName)}'
  params: {
    name: apimRouteTableName
    location: location
    routes: apimRoutes
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.0' = {
  scope: resourceGroup(networkResourceGroupName)
  name: 'virtualNetwork-${uniqueString(deployment().name, location, virtualNetworkName)}'
  params: {
    name: virtualNetworkName
    location: location
    addressPrefixes: virtualNetworkSettings.addressPrefixes
    dnsServers: virtualNetworkSettings.dnsServers
    subnets: [
      for subnet in virtualNetworkSettings.subnets: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        networkSecurityGroupResourceId: contains(subnet, 'networkSecurityGroup') && subnet.name == 'APIMSubnet'
          ? networkSecurityGroup.outputs.resourceId
          : null
        routeTableResourceId: contains(subnet, 'routeTable') && subnet.name == 'APIMSubnet'
          ? routeTable.outputs.resourceId
          : null
      }
    ]
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remoteVirtualNetworkResourceId: hubVirtualNetworkId
        useRemoteGateways: false
      }
    ]
    diagnosticSettings: [
      {
        name: '${virtualNetworkName}-${diagsSuffix}'
        workspaceResourceId: hubLogAnalyticsWorkspaceId
      }
    ]
  }
}

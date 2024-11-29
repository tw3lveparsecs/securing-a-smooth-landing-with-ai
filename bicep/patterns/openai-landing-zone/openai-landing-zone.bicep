targetScope = 'subscription'

param location string

param networkResourceGroupName string

param openaiResourceGroupName string

// added a conditional parameter to deploy the network watcher to cater for deployment scenarios in the same subscription
param deployNetworkWatcher bool = false

param networkWatcherName string = ''

param logAnalyticsWorkspaceName string

param hubLogAnalyticsWorkspaceId string

param hubVirtualNetworkId string

param openaiNsgName string

param openaiNsgRules array

param openaiRouteTableName string

param openaiRoutes array

param virtualNetworkName string

param virtualNetworkSettings object

param userAssignedIdentityName string

param openaiDnsZoneResourceId string

param openaiSettings array

var diagsSuffix = 'diags'

module networkResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'networkResourceGroup-${uniqueString(deployment().name, location, networkResourceGroupName)}'
  params: {
    name: networkResourceGroupName
    location: location
  }
}

module openaiResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'openaiResourceGroup-${uniqueString(deployment().name, location, openaiResourceGroupName)}'
  params: {
    name: openaiResourceGroupName
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
  dependsOn: [openaiResourceGroup]
  scope: resourceGroup(openaiResourceGroupName)
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
  name: 'networkSecurityGroup-${uniqueString(deployment().name, location, openaiNsgName)}'
  params: {
    name: openaiNsgName
    location: location
    securityRules: openaiNsgRules
    diagnosticSettings: [
      {
        name: '${openaiNsgName}-${diagsSuffix}'
        workspaceResourceId: hubLogAnalyticsWorkspaceId
      }
    ]
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.4.0' = {
  dependsOn: [networkResourceGroup]
  scope: resourceGroup(networkResourceGroupName)
  name: 'routeTable-${uniqueString(deployment().name, location, openaiRouteTableName)}'
  params: {
    name: openaiRouteTableName
    location: location
    routes: openaiRoutes
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
        networkSecurityGroupResourceId: contains(subnet, 'networkSecurityGroup') && subnet.name == 'AISubnet'
          ? networkSecurityGroup.outputs.resourceId
          : null
        routeTableResourceId: contains(subnet, 'routeTable') && subnet.name == 'AISubnet'
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

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  dependsOn: [openaiResourceGroup]
  scope: resourceGroup(openaiResourceGroupName)
  name: 'userAssignedIdentity-${uniqueString(deployment().name, location, userAssignedIdentityName)}'
  params: {
    name: userAssignedIdentityName
    location: location
  }
}

module openaiPrimary 'br/public:avm/res/cognitive-services/account:0.8.0' = [
  for (setting, i) in openaiSettings: {
    scope: resourceGroup(openaiResourceGroupName)
    name: 'openai-primary-${i}-${uniqueString(deployment().name, location, virtualNetworkName)}'
    params: {
      name: '${setting.name}-primary'
      kind: setting.kind
      customSubDomainName: '${setting.customSubDomainName}-primary'
      deployments: setting.deployments
      location: location
      managedIdentities: {
        userAssignedResourceIds: [
          userAssignedIdentity.outputs.resourceId
        ]
      }
      privateEndpoints: [
        {
          privateDnsZoneGroup: {
            privateDnsZoneGroupConfigs: [
              {
                privateDnsZoneResourceId: openaiDnsZoneResourceId
              }
            ]
          }
          subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
        }
      ]
      publicNetworkAccess: 'Disabled'
      diagnosticSettings: [
        {
          name: '${setting.name}-audit-${diagsSuffix}'
          workspaceResourceId: hubLogAnalyticsWorkspaceId
          logCategoriesAndGroups: [
            {
              categoryGroup: 'Audit'
              enabled: true
            }
          ]
          metricCategories: []
        }
        {
          name: '${setting.name}-app-${diagsSuffix}'
          workspaceResourceId: hubLogAnalyticsWorkspaceId
          logCategoriesAndGroups: [
            {
              category: 'Trace'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'AllMetrics'
              enabled: true
            }
          ]
        }
      ]
    }
  }
]

module openaiSecondary 'br/public:avm/res/cognitive-services/account:0.8.0' = [
  for (setting, i) in openaiSettings: {
    scope: resourceGroup(openaiResourceGroupName)
    name: 'openai-secondary-${i}-${uniqueString(deployment().name, location, virtualNetworkName)}'
    params: {
      name: '${setting.name}-secondary'
      kind: setting.kind
      customSubDomainName: '${setting.customSubDomainName}-secondary'
      deployments: setting.deployments
      location: location
      managedIdentities: {
        userAssignedResourceIds: [
          userAssignedIdentity.outputs.resourceId
        ]
      }
      privateEndpoints: [
        {
          privateDnsZoneGroup: {
            privateDnsZoneGroupConfigs: [
              {
                privateDnsZoneResourceId: openaiDnsZoneResourceId
              }
            ]
          }
          subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
        }
      ]
      publicNetworkAccess: 'Disabled'
      diagnosticSettings: [
        {
          name: '${setting.name}-audit-${diagsSuffix}'
          workspaceResourceId: hubLogAnalyticsWorkspaceId
          logCategoriesAndGroups: [
            {
              categoryGroup: 'Audit'
              enabled: true
            }
          ]
          metricCategories: []
        }
        {
          name: '${setting.name}-app-${diagsSuffix}'
          workspaceResourceId: hubLogAnalyticsWorkspaceId
          logCategoriesAndGroups: [
            {
              category: 'Trace'
              enabled: true
            }
          ]
          metricCategories: [
            {
              category: 'AllMetrics'
              enabled: true
            }
          ]
        }
      ]
    }
  }
]

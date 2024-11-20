targetScope = 'subscription'

param location string

param resourceGroupName string

param networkWatcherName string

param logAnalyticsWorkspaceName string

param bastionNsgName string

param virtualNetworkName string

param virtualNetworkSettings object

param privateLinkDnsZones array

param wafPolicyName string

param wafName string

param wafPublicIpName string

param wafSettings object

var diagsSuffix = 'diags'

module hubResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'resourceGroup-${uniqueString(deployment().name, location, resourceGroupName)}'
  params: {
    name: resourceGroupName
    location: location
  }
}

module networkWatcher 'br/public:avm/res/network/network-watcher:0.3.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'networkWatcher-${uniqueString(deployment().name, location, networkWatcherName)}'
  params: {
    name: networkWatcherName
    location: location
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'logAnalyticsWorkspace-${uniqueString(deployment().name, location, logAnalyticsWorkspaceName)}'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    skuName: 'PerGB2018'
  }
}

module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'networkSecurityGroup-${uniqueString(deployment().name, location, bastionNsgName)}'
  params: {
    name: bastionNsgName
    location: location
    securityRules: [
      {
        name: 'Allow-Inbound-Internet-AzureBastionSubnet-TCP-443'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 120
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-Inbound-GatewayManager-AzureBastionSubnet-TCP-443'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 130
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow_Inbound_AzureLB_Any_TCP_443'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 140
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow_Inbound_VirtualNetwork_VirtualNetwork_TCP_BastionHostComms'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 150
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'Deny-Inbound-Any'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 999
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Allow_Outbound_Any_VirtualNetwork_TCP_SSH-RDP'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 100
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'Allow_Outbound_Any_AzureCloud_TCP_443'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 110
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow_Outbound_VirtualNetwork_VirtualNetwork_Any_BastionHostComms'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 120
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'Allow_Outbound_Any_Internet_Any_80'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 130
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
        }
      }
    ]
    diagnosticSettings: [
      {
        name: '${bastionNsgName}-${diagsSuffix}'
        workspaceResourceId: workspace.outputs.resourceId
      }
    ]
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.0' = {
  scope: resourceGroup(resourceGroupName)
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
        networkSecurityGroupResourceId: contains(subnet, 'networkSecurityGroup') && subnet.name == 'AzureBastionSubnet'
          ? networkSecurityGroup.outputs.resourceId
          : null
      }
    ]
    diagnosticSettings: [
      {
        name: '${virtualNetworkName}-${diagsSuffix}'
        workspaceResourceId: workspace.outputs.resourceId
      }
    ]
  }
}

module privateDnsZones 'br/public:avm/res/network/private-dns-zone:0.6.0' = [
  for (privateDnsZone, i) in privateLinkDnsZones: {
    scope: resourceGroup(resourceGroupName)
    name: 'privateDnsZones-${i}-${uniqueString(deployment().name, location, virtualNetworkName)}'
    params: {
      name: privateDnsZone
      location: 'global'
    }
  }
]

module applicationGatewayWebApplicationFirewallPolicy 'br/public:avm/res/network/application-gateway-web-application-firewall-policy:0.1.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'applicationGatewayWebApplicationFirewallPolicy-${uniqueString(deployment().name, location,  wafPolicyName )}'
  params: {
    name: wafPolicyName
    location: location
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.7.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'applicationGatewayWebApplicationPublicIpAddress-${uniqueString(deployment().name, location,  wafPublicIpName )}'
  params: {
    name: wafPublicIpName
    location: location
  }
}

module applicationGateway 'br/public:avm/res/network/application-gateway:0.5.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'applicationGatewayWebApplicationFirewall-${uniqueString(deployment().name, location,  wafName )}'
  params: {
    name: wafName
    location: location
    backendAddressPools: wafSettings.backendAddressPools
    backendHttpSettingsCollection: wafSettings.backendHttpSettingsCollection
    frontendIPConfigurations: [
      for frontend in wafSettings.frontendIPConfigurations: {
        name: frontend.name
        properties: {
          publicIPAddress: {
            id: publicIpAddress.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: wafSettings.frontendPorts
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: virtualNetwork.outputs.subnetResourceIds[3]
          }
        }
      }
    ]
    httpListeners: [
      for httpListener in wafSettings.httpListeners: {
        name: httpListener.name
        properties: {
          frontendIPConfiguration: {
            id: '${hubResourceGroup.outputs.resourceId}/providers/Microsoft.Network/applicationGateways/${wafName}/frontendIPConfigurations/${httpListener.properties.frontendIPConfiguration.name}'
          }
          frontendPort: {
            id: '${hubResourceGroup.outputs.resourceId}/providers/Microsoft.Network/applicationGateways/${wafName}/frontendPorts/${httpListener.properties.frontendPort.name}'
          }
          hostName: httpListener.properties.?hostName ?? null
          protocol: httpListener.properties.protocol
        }
      }
    ]
    requestRoutingRules: [
      for rule in wafSettings.requestRoutingRules: {
        name: rule.name
        properties: {
          backendAddressPool: {
            id: '${hubResourceGroup.outputs.resourceId}/providers/Microsoft.Network/applicationGateways/${wafName}/backendAddressPools/${rule.properties.backendAddressPool.name}'
          }
          backendHttpSettings: {
            id: '${hubResourceGroup.outputs.resourceId}/providers/Microsoft.Network/applicationGateways/${wafName}/backendHttpSettingsCollection/${rule.properties.backendHttpSettings.name}'
          }
          httpListener: {
            id: '${hubResourceGroup.outputs.resourceId}/providers/Microsoft.Network/applicationGateways/${wafName}/httpListeners/${rule.properties.httpListener.name}'
          }
          priority: rule.priority
          ruleType: rule.ruleType
        }
      }
    ]
  }
}

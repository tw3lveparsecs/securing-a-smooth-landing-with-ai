using './connectivity.bicep'

param location = 'australiaeast'
param resourceGroupName = 'smooth-landing-ai-hub-rg'
param networkWatcherName = 'hub-ae-nw'
param logAnalyticsWorkspaceName = 'hub-ae-law'
param bastionNsgName = 'hub-ae-bastion-nsg'
param virtualNetworkName = 'hub-ae-vnet'
param virtualNetworkSettings = {
  addressPrefixes: ['10.70.0.0/16']
  dnsServers: []
  subnets: [
    {
      name: 'AzureBastionSubnet'
      addressPrefix: '10.70.0.0/24'
      networkSecurityGroup: 'hub-ae-bastion-nsg'
    }
    {
      name: 'AzureFirewallSubnet'
      addressPrefix: '10.70.1.0/24'
    }
    {
      name: 'GatewaySubnet'
      addressPrefix: '10.70.2.0/24'
    }
    {
      name: 'AzureWafSubnet'
      addressPrefix: '10.70.3.0/24'
    }
  ]
}

param privateLinkDnsZones = [
  'privatelink.openai.azure.com'
]
param wafName = 'hub-ae-apgw'

param wafPolicyName = 'hub-ae-waf'

param wafPublicIpName = 'hub-ae-waf-pip'

param wafSettings = {
  backendAddressPools: [
    {
      name: 'backendAddressPool1'
      properties: {
        backendAddresses: [
          {
            ipAddress: '10.1.0.4'
          }
        ]
      }
    }
  ]
  backendHttpSettingsCollection: [
    {
      name: 'backendHttpSettings1'
      properties: {
        cookieBasedAffinity: 'Disabled'
        port: 80
        protocol: 'Http'
      }
    }
  ]
  frontendIPConfigurations: [
    {
      name: 'frontendIPConfig1'
    }
  ]
  frontendPorts: [
    {
      name: 'frontendPort1'
      properties: {
        port: 80
      }
    }
  ]
  httpListeners: [
    {
      name: 'httpListener1'
      properties: {
        frontendIPConfiguration: {
          name: 'frontendIPConfig1'
        }
        frontendPort: {
          name: 'frontendPort1'
        }
        protocol: 'Http'
      }
    }
  ]
  requestRoutingRules: [
    {
      name: 'requestRoutingRule1'
      priority: 100
      ruleType: 'Basic'
      properties: {
        backendAddressPool: {
          name: 'backendAddressPool1'
        }
        backendHttpSettings: {
          name: 'backendHttpSettings1'
        }
        httpListener: {
          name: 'httpListener1'
        }
      }
    }
  ]
}

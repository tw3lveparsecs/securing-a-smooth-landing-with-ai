using './openai-landing-zone.bicep'

param location = 'australiaeast'
param networkResourceGroupName = 'smooth-landing-ai-openai-network-rg'
param openaiResourceGroupName = 'smooth-landing-ai-openai-rg'
param deployNetworkWatcher = false
param networkWatcherName = 'openai-ae-nw'
param logAnalyticsWorkspaceName = 'openai-ae-law'
param hubLogAnalyticsWorkspaceId = '<enter_log_analytics_workspace_resource_id>'
param hubVirtualNetworkId = '<enter_hub_virtual_network_resource_id>'
param openaiNsgName = 'openai-ae-nsg'
param openaiNsgRules = []
param openaiRouteTableName = 'openai-ae-rt'
param openaiRoutes = []
param virtualNetworkName = 'openai-ae-vnet'
param virtualNetworkSettings = {
  addressPrefixes: ['10.90.0.0/16']
  dnsServers: []
  subnets: [
    {
      name: 'AISubnet'
      addressPrefix: '10.90.0.0/24'
      networkSecurityGroup: 'openai-ae-nsg'
      routeTable: 'openai-ae-rt'
    }
  ]
}
param userAssignedIdentityName = 'openai-ae-smooth-ai-id'
param openaiDnsZoneResourceId = '<enter_dns_zone_resource_id>'
param openaiSettings = [
  {
    name: 'smooth-ai-lz-10'
    kind: 'OpenAI'
    customSubDomainName: 'smooth-ai-lz-10'
    deployments: [
      {
        model: {
          format: 'OpenAI'
          name: 'gpt-4-32k'
          version: '0613'
        }
        name: 'gpt-4-32k'
        sku: {
          capacity: 10
          name: 'Standard'
        }
      }
    ]
  }
]

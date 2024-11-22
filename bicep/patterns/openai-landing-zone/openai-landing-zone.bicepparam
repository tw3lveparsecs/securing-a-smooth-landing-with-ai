using './openai-landing-zone.bicep'

param location = 'australiaeast'
param networkResourceGroupName = 'smooth-landing-ai-openai-network-rg'
param openaiResourceGroupName = 'smooth-landing-ai-openai-rg'
param deployNetworkWatcher = true
param networkWatcherName = 'openai-ae-nw'
param logAnalyticsWorkspaceName = 'openai-ae-law'
param hubLogAnalyticsWorkspaceId = '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourcegroups/smooth-landing-ai-hub-rg/providers/microsoft.operationalinsights/workspaces/hub-ae-law'
param hubVirtualNetworkId = '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/smooth-landing-ai-hub-rg/providers/Microsoft.Network/virtualNetworks/hub-ae-vnet'
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
param openaiDnsZoneResourceId = '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/smooth-landing-ai-hub-rg/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com'
param openaiSettings = [
  {
    name: 'smooth-ai-lz-01'
    kind: 'OpenAI'
    customSubDomainName: 'smooth-ai-lz-01'
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

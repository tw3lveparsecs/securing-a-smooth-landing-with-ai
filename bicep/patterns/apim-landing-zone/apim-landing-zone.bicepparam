using './apim-landing-zone.bicep'

param location = 'australiaeast'
param networkResourceGroupName = 'smooth-landing-ai-apim-network-rg'
param apimResourceGroupName = 'smooth-landing-ai-apim-rg'
param deployNetworkWatcher = true
param networkWatcherName = 'apim-ae-nw'
param logAnalyticsWorkspaceName = 'apim-ae-law'
param hubLogAnalyticsWorkspaceId = '<insert_hub_log_analytics_workspace_resource_id>'
param hubVirtualNetworkId = '<insert_hub_virtual_network_resource_id>'
param apimNsgName = 'apim-ae-nsg'
param apimNsgRules = [
  {
    name: 'Client_communication_to_API_Management'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
      destinationPortRanges: [
        '80'
        '443'
      ]
    }
  }
  {
    name: 'Management_endpoint_for_Azure_portal_and_Powershell'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3443'
      sourceAddressPrefix: 'ApiManagement'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'Azure_Infrastructure_Load_Balancer'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '6390'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 125
      direction: 'Inbound'
    }
  }
  {
    name: 'Azure_Traffic_Manager_routing_for_multi_region_deployment'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'AzureTrafficManager'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'Dependency_on_Azure_Storage_for_core_service_functionality'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '433'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Storage'
      access: 'Allow'
      priority: 140
      direction: 'Outbound'
    }
  }
  {
    name: 'Access_to_Azure_SQL_endpoints_for_core_service_functionality'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '1433'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Sql'
      access: 'Allow'
      priority: 150
      direction: 'Outbound'
    }
  }
  {
    name: 'Access_to_Azure_Key_Vault_for_core_service_functionality'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureKeyVault'
      access: 'Allow'
      priority: 160
      direction: 'Outbound'
    }
  }
  {
    name: 'Publish_Diagnostics_Logs_and_Metrics_Resource_Health_and_Application_Insights'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '1886'
        '443'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureMonitor'
      access: 'Allow'
      priority: 170
      direction: 'Inbound'
    }
  }
]
param apimRouteTableName = 'apim-ae-rt'
param apimRoutes = [
  {
    name: 'ApimToInternet'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'Internet'
    }
  }
]
param virtualNetworkName = 'apim-ae-vnet'
param virtualNetworkSettings = {
  addressPrefixes: ['10.80.0.0/16']
  dnsServers: []
  subnets: [
    {
      name: 'APIMSubnet'
      addressPrefix: '10.80.0.0/24'
      networkSecurityGroup: 'apim-ae-nsg'
      routeTable: 'apim-ae-rt'
    }
  ]
}
param apimName = 'shared-ae-apim-01'

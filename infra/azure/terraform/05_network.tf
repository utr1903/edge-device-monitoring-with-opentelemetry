### Network ###

# VNET
resource "azurerm_virtual_network" "platform" {
  name                = local.vnet_name
  address_space       = ["192.168.0.0/20"]
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
}

# Subnet - Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "gateway"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes = [
    local.subnet_cidr_gateway,
  ]
}

# Subnet - Edge
resource "azurerm_subnet" "edge" {
  name                 = "edge"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes = [
    local.subnet_cidr_edge,
  ]
}

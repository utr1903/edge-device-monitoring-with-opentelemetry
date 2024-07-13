##############
### Locals ###
##############

locals {

  # Resource group
  resource_group_name = "rg${var.project}platform${var.instance}"

  # Virtual network
  vnet_name     = "vnet${var.project}platform${var.instance}"
  priv_dns_name = "prvdns${var.project}platform${var.instance}"

  # VM - Gateway
  subnet_cidr_gateway = cidrsubnet(azurerm_virtual_network.platform.address_space[0], 6, 3)
  nsg_name_gateway    = "nsggw${var.project}platform${var.instance}"
  pubib_name_gateway  = "pubipgw${var.project}platform${var.instance}"
  nic_name_gateway    = "nicgw${var.project}platform${var.instance}"
  vm_name_gateway     = "vmgw${var.project}platform${var.instance}"

  # VM - Edge
  subnet_cidr_edge = cidrsubnet(azurerm_virtual_network.platform.address_space[0], 4, 1)
  nsg_name_edge    = "nsgedge${var.project}platform${var.instance}"
  pubib_name_edge  = "pubipedge${var.project}platform${var.instance}"
  nic_name_edge    = "nicedge${var.project}platform${var.instance}"
  vm_name_edge     = "vmedge${var.project}platform${var.instance}"
}

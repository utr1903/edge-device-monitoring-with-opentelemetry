### Gateway ###

# Network Security Group - gateway
resource "azurerm_network_security_group" "gateway" {
  name                = local.nsg_name_gateway
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
}

# Network Security Rule
resource "azurerm_network_security_rule" "gateway_allow_ssh_to_22" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.platform.name
  network_security_group_name = azurerm_network_security_group.gateway.name
}

# Associate NSG with gateway subnet
resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Public IP for the gateway VM
resource "azurerm_public_ip" "gateway_vm" {
  name                = local.pubib_name_gateway
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  allocation_method   = "Dynamic"
}

# Network Interface for the VM
resource "azurerm_network_interface" "gateway_vm" {
  name                = local.nic_name_gateway
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gateway_vm.id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "gateway_vm" {
  name                = local.vm_name_gateway
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  size           = "Standard_DS1_v2"
  admin_username = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.gateway_vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type = "SystemAssigned"
  }

  user_data = base64encode(local.init_script_for_gateway_vm)
}

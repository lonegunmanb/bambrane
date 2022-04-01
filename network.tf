resource "azurerm_subnet" "runner" {
  name                 = var.runner_subnet_name
  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  address_prefixes     = [var.runner_address_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_security_group" "ghrunner" {
  location            = var.resource_group.location
  name                = var.runner_network_security_group_name
  resource_group_name = var.resource_group.name
  tags                = var.runner_network_security_group_tags
}

resource "azurerm_network_security_rule" "no_inbound" {
  name                         = "no_inbound"
  resource_group_name          = var.resource_group.name
  access                       = "Deny"
  direction                    = "Inbound"
  network_security_group_name  = azurerm_network_security_group.ghrunner.name
  priority                     = 200
  protocol                     = "*"
  source_address_prefixes      = ["0.0.0.0/0"]
  source_port_range            = "*"
  destination_address_prefixes = azurerm_subnet.runner.address_prefixes
  destination_port_range       = local.dummy_port
}

resource "azurerm_subnet_network_security_group_association" "ghrunner" {
  network_security_group_id = azurerm_network_security_group.ghrunner.id
  subnet_id                 = azurerm_subnet.runner.id
}

resource "azurerm_network_profile" "runner" {
  name                = var.runner_network_profile_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  container_network_interface {
    name = "runnernic"
    ip_configuration {
      name      = "runner"
      subnet_id = azurerm_subnet.runner.id
    }
  }

  tags = var.network_profile_tags
}
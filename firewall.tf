resource "azurerm_subnet" "azure_firewall" {
  # This subnet's name must be `AzureFirewallSubnet`.
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group.name
  virtual_network_name = var.virtual_network.name
  address_prefixes     = var.firewall_subnet_address_prefixes
}

resource "azurerm_public_ip" "firewall_public_ip" {
  name                = var.firewall_public_ip_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.firewall_public_ip_tags
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku_tier            = "Standard"
  sku_name            = "AZFW_VNet"
  tags                = var.firewall_tags

  ip_configuration {
    name                 = "ip_configuration"
    subnet_id            = azurerm_subnet.azure_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
}

resource "azurerm_firewall_application_rule_collection" "gh" {
  action              = "Allow"
  azure_firewall_name = azurerm_firewall.firewall.name
  name                = "Allow"
  priority            = 101
  resource_group_name = var.resource_group.name

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      name             = rule.value.name
      source_addresses = var.virtual_network.address_space
      target_fqdns     = rule.value.target_fqdns
      protocol {
        port = 443
        type = "Https"
      }
      protocol {
        port = 80
        type = "Http"
      }
    }
  }
}

resource "azurerm_route_table" "runner_rt" {
  location            = var.resource_group.location
  name                = var.route_table_name
  resource_group_name = var.resource_group.name
  tags                = var.route_table_tags
}

# All traffic to the internet must be filtered by the firewall.
resource "azurerm_route" "ghrunner" {
  address_prefix         = "0.0.0.0/0"
  name                   = "all"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  resource_group_name    = var.resource_group.name
  route_table_name       = azurerm_route_table.runner_rt.name
}

# Runners cannot communicate with each other.
resource "azurerm_route" "no_internal_route" {
  address_prefix      = var.runner_address_prefix
  name                = "no_internal_route"
  next_hop_type       = "None"
  resource_group_name = var.resource_group.name
  route_table_name    = azurerm_route_table.runner_rt.name
}

resource "azurerm_subnet_route_table_association" "ghrunner" {
  route_table_id = azurerm_route_table.runner_rt.id
  subnet_id      = azurerm_subnet.runner.id
}


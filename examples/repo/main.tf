resource "azurerm_resource_group" "runner" {
  name     = "gh-aci-runner-${random_string.suffix.result}"
  location = "West Europe"
}

resource "azurerm_virtual_network" "runner" {
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.runner.location
  name                = "vnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.runner.name
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = false
}

module "runners" {
  source              = "../../"
  github_access_token = var.github_access_token
  github_repos        = var.github_repos

  resource_group = {
    name     = azurerm_resource_group.runner.name
    location = azurerm_resource_group.runner.location
  }
  virtual_network = {
    name          = azurerm_virtual_network.runner.name
    address_space = azurerm_virtual_network.runner.address_space
  }
  firewall_subnet_address_prefixes   = ["10.0.1.0/24"]
  firewall_name                      = "bambrane-fw-${random_string.suffix.result}"
  firewall_public_ip_name            = "ghrunner-firewall-public-ip-${random_string.suffix.result}"
  repo_runner_name_prefix            = "ghrunner-repo-${random_string.suffix.result}"
  route_table_name                   = "bambrane-route-table-${random_string.suffix.result}"
  runner_subnet_name                 = "runner-${random_string.suffix.result}"
  runner_network_security_group_name = "ghrunner-${random_string.suffix.result}"
}
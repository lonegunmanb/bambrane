# Bambrane

Bambrane is an acceptance test solution for Iac project on Azure platform.

Today we have many Terraform community modules, and we'd like to integrate them with an automatic end-end test pipeline on GitHub Action. The problem is: how do we manage our secret?

Though we can store our Azure client secret in GitHub Action secret, when we execute test code for pull request, the potential malicious embedded in the pr may exfiltrate our secret by printing it out or sending it via the internet.

Many projects maintain their own private pipeline so no external user can access the output, but the secret can still be leaked through the network.

Even worse, the attacker may use this private pipeline runner against us, install malicious program, infiltrate our private network, or break the test to cause the resource leak.

Bambrane is a solution to prevent such attacks.

Bambrane provisions [self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) as CI runner so we can bind a [MSI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) on the runner instance. By using MSI we eliminated the secret so there's no secret to hide or steal.

We select [Azure Container Instance](https://docs.microsoft.com/en-us/azure/container-instances/) as the runner's runtime so we can leverage the isolation protection the ACI provides. Every time the test is over or timeout, the container will be restarted, and as we have attached no persistent volume on it, all changes to the filesystem will be erased after the restart.

Bambrane also setup a route table to route all runner's outbound internet traffic to an [Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/overview). The firewall enforce an allow-list to these traffic so only the website in the list can be accessed during the test. All network traffic inside the private subnet will be discarded via the route table so that no runner can interact with other runner.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                | Version  |
|---------------------------------------------------------------------|----------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null)          | >= 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random)    | >= 3.1.0 |

## Providers

| Name                                                          | Version  |
|---------------------------------------------------------------|----------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0.0 |
| <a name="provider_null"></a> [null](#provider\_null)          | >= 3.0.0 |
| <a name="provider_random"></a> [random](#provider\_random)    | >= 3.1.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                                    | Type        |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azurerm_container_group.org_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group)                                                   | resource    |
| [azurerm_container_group.repo_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group)                                                  | resource    |
| [azurerm_firewall.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall)                                                                   | resource    |
| [azurerm_firewall_application_rule_collection.gh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_application_rule_collection)                 | resource    |
| [azurerm_network_profile.runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_profile)                                                       | resource    |
| [azurerm_network_security_group.ghrunner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)                                       | resource    |
| [azurerm_network_security_rule.no_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule)                                       | resource    |
| [azurerm_public_ip.firewall_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                                                       | resource    |
| [azurerm_role_assignment.org_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                                              | resource    |
| [azurerm_role_assignment.repo_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                                             | resource    |
| [azurerm_route.ghrunner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route)                                                                         | resource    |
| [azurerm_route.no_internal_route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route)                                                                | resource    |
| [azurerm_route_table.runner_rt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table)                                                            | resource    |
| [azurerm_subnet.azfw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                           | resource    |
| [azurerm_subnet.runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                         | resource    |
| [azurerm_subnet_network_security_group_association.ghrunner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource    |
| [azurerm_subnet_route_table_association.ghrunner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association)                       | resource    |
| [azurerm_user_assigned_identity.org_aci](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity)                                        | resource    |
| [azurerm_user_assigned_identity.repo_aci](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity)                                       | resource    |
| [null_resource.person_token_trigger](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)                                                             | resource    |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string)                                                                           | resource    |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription)                                                         | data source |

## Inputs

| Name                                                                                                  | Description                                                                                                                                                                                                                                | Type                                                                                          | Default                                             | Required |
|-------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-----------------------------------------------------|:--------:|
| <a name="input_github_access_token"></a> [github\_access\_token](#input\_github\_access\_token)       | The access token used to register the runner. For repo's runner ,the token must has public\_repo scope on the repo. For organization's runner, the token must has `admin:org` scope on the organization and is `Owner` of the organization | `string`                                                                                      | n/a                                                 |   yes    |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org)                                    | The GitHub Org the runners belong to.                                                                                                                                                                                                      | `string`                                                                                      | `null`                                              |    no    |
| <a name="input_github_repos"></a> [github\_repos](#input\_github\_repos)                              | The GitHub repos' https url that the runners belong to. Each repo will be assigned one runner.                                                                                                                                             | `list(string)`                                                                                | `null`                                              |    no    |
| <a name="input_init_image"></a> [init\_image](#input\_init\_image)                                    | The container image used by aci's init container.                                                                                                                                                                                          | `string`                                                                                      | `"aztfmod.azurecr.io/testrunner/init"`              |    no    |
| <a name="input_init_image_tag"></a> [init\_image\_tag](#input\_init\_image\_tag)                      | The container image's tag used by aci's init container.                                                                                                                                                                                    | `string`                                                                                      | `"v0.0.1"`                                          |    no    |
| <a name="input_org_runner_count"></a> [org\_runner\_count](#input\_org\_runner\_count)                | How many runners we want to keep as the shared runners for the organization. If `var.github_org` is `null`, this variable is useless.                                                                                                      | `number`                                                                                      | `1`                                                 |    no    |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group)                        | The resource group we'd like to put our runners and other resources in. All fields are required.                                                                                                                                           | <pre>object({<br>    name     = string<br>    location = string<br>  })</pre>                 | n/a                                                 |   yes    |
| <a name="input_runner_address_prefix"></a> [runner\_address\_prefix](#input\_runner\_address\_prefix) | The runner's subnet's cidr.                                                                                                                                                                                                                | `string`                                                                                      | `"10.0.0.0/24"`                                     |    no    |
| <a name="input_runner_image"></a> [runner\_image](#input\_runner\_image)                              | The container image used by aci's container.                                                                                                                                                                                               | `string`                                                                                      | `"aztfmod.azurecr.io/testrunner/tfmodule-ghrunner"` |    no    |
| <a name="input_runner_image_tag"></a> [runner\_image\_tag](#input\_runner\_image\_tag)                | The container image's tag used by aci's container.                                                                                                                                                                                         | `string`                                                                                      | `"v0.0.1"`                                          |    no    |
| <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network)                     | The virtual network we'd like to put our runners and other resources in.                                                                                                                                                                   | <pre>object({<br>    name          = string<br>    address_space = list(string)<br>  })</pre> | n/a                                                 |   yes    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

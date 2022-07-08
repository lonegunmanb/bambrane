variable "container_group_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the runners' container instances."
}

variable "firewall_name" {
  type        = string
  default     = "BambraneFirewall"
  description = "Specifies the name of the Firewall of runners' container network. Changing this forces new resources to be created."
  nullable    = false
}

variable "firewall_public_ip_name" {
  type        = string
  default     = "ghrunner-firewall-public-ip"
  description = "Specifies the name of the public IP for firewall."
  nullable    = false
}

variable "firewall_public_ip_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the firewall's public ip."
}

variable "firewall_rules" {
  type = list(object({
    name         = string
    target_fqdns = list(string)
  }))
  default = [
    {
      name         = "AllowGithub"
      target_fqdns = ["*.github.com", "*.github.io", "github.com", "*.githubusercontent.com"]
    },
    {
      name         = "AllowTerraform"
      target_fqdns = ["registry.terraform.io", "releases.hashicorp.com"]
    },
    {
      name         = "AllowACR"
      target_fqdns = ["*.azurecr.io"]
    },
    {
      name         = "AzureAPI"
      target_fqdns = ["management.azure.com"]
    },
    {
      name         = "gotest"
      target_fqdns = [
        "proxy.golang.org",
        "cloud.google.com",
        "google.golang.org",
        "storage.googleapis.com",
        "sum.golang.org",
      ]
    },
    {
      name         = "azure_metadata"
      target_fqdns = ["169.254.169.254"]
    },
    {
      name         = "ipify.org"
      target_fqdns = ["api.ipify.org"]
    },
    {
      name = "azure_keyvault"
      target_fqdns = ["*.vault.azure.net"]
    }
  ]
  description = "Websites that the runners are allowed to access via 80 and 443."
  nullable    = false
  validation {
    condition     = alltrue([for rule in var.firewall_rules : length(rule.target_fqdns) > 0])
    error_message = "No empty target_fqdns list was allowed."
  }
}

variable "firewall_subnet_address_prefixes" {
  type        = list(string)
  description = "The address prefixes to use for the firewall's subnet."
  nullable    = false
}

variable "firewall_tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the firewall."
  default     = null
}

variable "github_org" {
  type        = string
  description = "The GitHub Org the runners belong to."
  default     = null
}

variable "github_access_token" {
  type        = string
  description = "The access token used to register the runner. For repo's runner ,the token must has public_repo scope on the repo. For organization's runner, the token must has `admin:org` scope on the organization and is `Owner` of the organization"
  nullable    = false
  sensitive   = true
}

variable "github_repos" {
  type        = list(string)
  default     = null
  description = "The GitHub repos' https url that the runners belong to. Each repo will be assigned one runner."
}

variable "token_image" {
  type        = string
  default     = "aztfmod.azurecr.io/testrunner/token"
  description = "The container image used to generate github runner registry token."
}

variable "token_image_tag" {
  type        = string
  default     = "v0.0.2"
  description = "The container image's tag used to generate github runner registry token."
}

variable "network_profile_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the runner containers' network profile."
}

variable "org_runner_count" {
  type        = number
  default     = 1
  description = "How many runners we want to keep as the shared runners for the organization. If `var.github_org` is `null`, this variable is useless."
  validation {
    condition     = var.org_runner_count > 0
    error_message = "`org_runner_count` should be a positive integer."
  }
}

variable "org_runner_name_prefix" {
  type        = string
  default     = "ghrunner-org"
  description = "Prefix for org runner container instance's name. Cannot be `null`."
  nullable    = false
}

variable "org_user_assigned_identity_name_prefix" {
  type        = string
  default     = "ghrunner-aci-org"
  description = "Prefix for org runner's user assigned identity name. Cannot be `null`."
  nullable    = false
}

variable "repo_runner_name_prefix" {
  type        = string
  default     = "ghrunner-aci"
  description = "Prefix for repo runner container instance's name. Cannot be `null`."
  nullable    = false
}

variable "repo_user_assigned_identity_name_prefix" {
  type        = string
  default     = "ghrunner-aci"
  description = "Prefix for repo runner's user assigned identity name. Cannot be `null`."
  nullable    = false
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "The resource group we'd like to put our runners and other resources in. All fields are required."
  nullable    = false
  validation {
    condition     = var.resource_group.name != null && var.resource_group.name != ""
    error_message = "`resource_group.name` is required."
  }
  validation {
    condition     = var.resource_group.location != null && var.resource_group.location != ""
    error_message = "`resource_group.location` is required."
  }
}

variable "route_table_name" {
  type        = string
  default     = "rt_runner"
  description = "The name of the runners' route table. Changing this forces new resources to be created."
  nullable    = false
}

variable "route_table_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the runner's route table."
}

variable "runner_address_prefix" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The runner's subnet's cidr."
  nullable    = false
}

variable "runner_image" {
  type        = string
  default     = "aztfmod.azurecr.io/testrunner/tfmodule-ghrunner"
  description = "The container image used by aci's container."
}

variable "runner_image_tag" {
  type        = string
  default     = "v0.0.8"
  description = "The container image's tag used by aci's container."
}

variable "runner_network_profile_name" {
  type        = string
  default     = "runner"
  description = "Name for runner container's network profile."
  nullable    = false
}

variable "runner_network_security_group_name" {
  type        = string
  default     = "ghrunner-nsg"
  description = "Name of the network security group created for the runner containers."
  nullable    = false
}

variable "runner_network_security_group_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the runner's network security group."
}

variable "runner_subnet_name" {
  default     = "runner-subnet"
  description = "The name of the runners' subnet. Changing this forces new resources to be created."
  nullable    = false
}

variable "user_assigned_identity_tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the generated user assigned identities."
}

variable "virtual_network" {
  type = object({
    name          = string
    address_space = list(string)
  })
  description = "The virtual network we'd like to put our runners and other resources in."
  nullable    = false
  validation {
    condition     = var.virtual_network.name != null && var.virtual_network != ""
    error_message = "`virtual_network.name` is required."
  }
  validation {
    condition     = var.virtual_network.address_space == null ? false : length(var.virtual_network.address_space) > 0
    error_message = "`virtual_network.address_space` is required."
  }
}

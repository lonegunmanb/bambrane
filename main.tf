data "azurerm_subscription" "current" {}

resource "azurerm_user_assigned_identity" "repo_aci" {
  for_each = toset(local.repos)

  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  name                = "${var.repo_user_assigned_identity_name_prefix}-${local.repo_names[each.value]}"

  tags = var.user_assigned_identity_tags
}

resource "azurerm_user_assigned_identity" "org_aci" {
  count = var.github_org == null ? 0 : var.org_runner_count

  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  name                = "${var.org_user_assigned_identity_name_prefix}-${count.index}"

  tags = var.user_assigned_identity_tags
}

resource "azurerm_role_assignment" "repo_contributor" {
  for_each = toset(local.repos)

  principal_id         = azurerm_user_assigned_identity.repo_aci[each.value].principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
}

resource "azurerm_role_assignment" "org_contributor" {
  count = var.github_org == null ? 0 : var.org_runner_count

  principal_id         = azurerm_user_assigned_identity.org_aci[count.index].principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
}

locals {
  repo_resource_group_names = {for k, i in azurerm_user_assigned_identity.repo_aci : k => "ghrunner-${md5(i.principal_id)}"}
  org_resource_group_names  = [for i in azurerm_user_assigned_identity.org_aci : "ghrunner-${md5(i.principal_id)}"]
}

resource "null_resource" "person_token_trigger" {
  triggers = {
    token = var.github_access_token
  }
}

resource "azurerm_container_group" "repo_runner" {
  for_each = toset(local.repos)

  name                = "${var.repo_runner_name_prefix}-${local.repo_names[each.value]}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.runner.id
  os_type             = "Linux"
  restart_policy      = "Always"

  init_container {
    name                  = "init"
    image                 = "${var.init_image}:${var.init_image_tag}"
    environment_variables = {
      RUNNER_SCOPE = "repo"
      OWNER        = local.repo_owners[each.value]
      REPO         = local.repo_names[each.value]
    }
    secure_environment_variables = {
      ACCESS_TOKEN = var.github_access_token
    }
    volume {
      name       = "token"
      mount_path = "/token"
      read_only  = false
      empty_dir  = true
    }
  }
  container {
    name                  = "runner"
    image                 = "${var.runner_image}:${var.runner_image_tag}"
    cpu                   = "2"
    memory                = "2"
    environment_variables = {
      ARM_USE_MSI                = "true",
      DISABLE_AUTO_UPDATE        = "true",
      EPHEMERAL                  = "true",
      LABELS                     = "self-hosted,tfmodule,${var.runner_image_tag}",
      MSI_ID                     = azurerm_user_assigned_identity.repo_aci[each.value].principal_id
      REPO                       = local.repo_names[each.value],
      REPO_URL                   = each.value
      RESOURCE_GROUP_NAME        = local.repo_resource_group_names[each.value]
      RUNNER_ALLOW_RUNASROOT     = "1",
      RUNNER_NAME                = "${var.repo_runner_name_prefix}-${local.repo_names[each.value]}",
      RUNNER_SCOPE               = "repo",
      TF_VAR_resource_group_name = local.repo_resource_group_names[each.value]
    }
    volume {
      name       = "token"
      mount_path = "/token"
      read_only  = false
      empty_dir  = true
    }
    ports {
      port     = local.dummy_port
      protocol = "UDP"
    }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.repo_aci[each.value].id]
  }

  # Since the secured environment variables cannot be read outside the container, we need ignore it https://docs.microsoft.com/en-us/azure/container-instances/container-instances-environment-variables#secure-values
  lifecycle {
    ignore_changes       = [init_container[0].secure_environment_variables]
    replace_triggered_by = [null_resource.person_token_trigger.id]
  }

  tags = var.container_group_tags

  depends_on = [azurerm_firewall_application_rule_collection.gh]
}

resource "azurerm_container_group" "org_runner" {
  count = var.github_org == null ? 0 : var.org_runner_count

  name                = "${var.org_runner_name_prefix}-${var.github_org}-${count.index}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.runner.id
  os_type             = "Linux"
  restart_policy      = "Always"

  init_container {
    name                  = "init"
    image                 = "${var.init_image}:${var.init_image_tag}"
    environment_variables = {
      RUNNER_SCOPE = "org"
      ORG          = var.github_org
    }
    secure_environment_variables = {
      ACCESS_TOKEN = var.github_access_token
    }
    volume {
      name       = "token"
      mount_path = "/token"
      read_only  = false
      empty_dir  = true
    }
  }
  container {
    name                  = "runner"
    image                 = "${var.runner_image}:${var.runner_image_tag}"
    cpu                   = "2"
    memory                = "2"
    environment_variables = {
      ARM_USE_MSI                = "true",
      DISABLE_AUTO_UPDATE        = "true",
      EPHEMERAL                  = "true",
      LABELS                     = "self-hosted,tfmodule,${var.runner_image_tag}",
      MSI_ID                     = azurerm_user_assigned_identity.org_aci[count.index].principal_id
      ORG_NAME                   = var.github_org
      RESOURCE_GROUP_NAME        = local.org_resource_group_names[count.index]
      RUNNER_ALLOW_RUNASROOT     = "1",
      RUNNER_NAME                = "${var.repo_runner_name_prefix}-${local.org_resource_group_names[count.index]}",
      RUNNER_SCOPE               = "org",
      TF_VAR_resource_group_name = local.org_resource_group_names[count.index]
    }
    volume {
      name       = "token"
      mount_path = "/token"
      read_only  = false
      empty_dir  = true
    }
    ports {
      port     = local.dummy_port
      protocol = "UDP"
    }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.org_aci[count.index].id]
  }

  # Since the secured environment variables cannot be read outside the container, we need ignore it https://docs.microsoft.com/en-us/azure/container-instances/container-instances-environment-variables#secure-values
  lifecycle {
    ignore_changes       = [init_container[0].secure_environment_variables]
    replace_triggered_by = [null_resource.person_token_trigger.id]
  }

  tags = var.container_group_tags

  depends_on = [azurerm_firewall_application_rule_collection.gh]
}

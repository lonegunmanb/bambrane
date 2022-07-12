output "repo_user_assigned_identities" {
  description = "Map of user assigned identities for repo aci runners. Key is repo url."
  value       = azurerm_user_assigned_identity.repo_aci
}

output "org_user_assigned_identities" {
  description = "Map of user assigned identities for org aci runners. Key is org name."
  value       = azurerm_user_assigned_identity.org_aci
}
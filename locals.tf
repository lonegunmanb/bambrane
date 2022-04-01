locals {
  dummy_port  = 65534
  repos       = var.github_repos == null ? [] : var.github_repos
  repo_names  = { for repo in local.repos : repo => reverse(split("/", repo))[0] }
  repo_owners = { for repo in local.repos : repo => reverse(split("/", repo))[1] }
}
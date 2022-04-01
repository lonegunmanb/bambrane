variable "github_access_token" {
  type        = string
  description = "The access token used to register the runner. For repo's runner ,the token must has public_repo scope on the repo. For organization's runner, the token must has `admin:org` scope on the organization and is `Owner` of the organization"
  nullable    = false
  sensitive   = true
}

variable "github_repos" {
  type = list(string)
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.10.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.0"
    }
  }
}
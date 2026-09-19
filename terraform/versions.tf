terraform {
  backend "azurerm" {
    resource_group_name  = "shared"
    storage_account_name = "mitchfenner"
    container_name       = "tfstate"
    key                  = "homelab.tfstate"
    subscription_id      = "c50e892e-1a7b-4ce6-8880-fc52843e6c4b"
    use_azuread_auth     = true
  }

  required_version = ">= 1.7.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }
}
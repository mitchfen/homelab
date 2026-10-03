terraform {
  required_version = ">= 1.7.0"

  backend "azurerm" {
    resource_group_name  = "shared"
    storage_account_name = "mitchfenner"
    container_name       = "tfstate"
    key                  = "homelab.tfstate"
    subscription_id      = "c50e892e-1a7b-4ce6-8880-fc52843e6c4b"
    use_azuread_auth     = true
    # encrypted by default in Azure Storage. No encrypt = true needed.
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "kubectl" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}
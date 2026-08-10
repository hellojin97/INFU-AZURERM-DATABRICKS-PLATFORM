terraform {
  required_version = ">= 1.15"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.124"
    }
  }

  backend "azurerm" {}
}

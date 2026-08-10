data "terraform_remote_state" "platform" {
  backend = "azurerm"

  config = {
    resource_group_name  = "INFU-TFSTATE-RG-CAC"
    storage_account_name = "infutfstateblobcac"
    container_name       = "tfstate"
    key                  = "dev/platform.tfstate"

    use_azuread_auth = true
    use_oidc         = true
  }
}

provider "databricks" {
  host      = "https://${data.terraform_remote_state.platform.outputs.workspace_url}"
  auth_type = "azure-cli"

  azure_client_id = var.azure_client_id
  azure_tenant_id = var.azure_tenant_id
}

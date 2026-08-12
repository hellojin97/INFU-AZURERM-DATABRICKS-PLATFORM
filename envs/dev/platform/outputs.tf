output "workspace_url" {
  value       = azurerm_databricks_workspace.this.workspace_url
  description = "workspace 호스트명. workspace 계층이 databricks provider의 host에 쓴다."
}

output "workspace_id" {
  value       = azurerm_databricks_workspace.this.workspace_id
  description = "Databricks Control Plane의 workspace 숫자 ID."
}

output "workspace_resource_id" {
  value       = azurerm_databricks_workspace.this.id
  description = "workspace의 Azure 리소스 ID. databricks provider의 azure_workspace_resource_id에 쓴다."
}

output "access_connector_id" {
  value       = azurerm_databricks_access_connector.this.id
  description = "UC storage credential이 참조할 Access Connector의 Azure 리소스 ID."
}

output "adls_storage_account_name" {
  value       = azurerm_storage_account.adls.name
  description = "external location URL 조립에 쓸 ADLS 계정 이름."
}

output "managed_container_name" {
  value       = azurerm_storage_container.managed.name
  description = "catalog managed storage로 쓸 ADLS container 이름. external location URL 조립에 쓴다."
}

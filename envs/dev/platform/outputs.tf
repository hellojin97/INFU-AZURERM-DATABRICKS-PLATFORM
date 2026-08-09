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
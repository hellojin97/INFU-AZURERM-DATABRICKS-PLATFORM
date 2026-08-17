# serverless는 VNet 밖 Databricks 네트워크에서 돌아 NCC 없이는 public access 차단된 ADLS 접근 불가

# 리전 단위. 이름 규칙 ^[0-9a-zA-Z-_]{3,30}$
resource "databricks_mws_network_connectivity_config" "this" {
  provider = databricks.account
  name     = "${local.name_prefix}-NCC-${local.location_abbreviation}"
  region   = var.location
}

# workspace당 NCC 하나. 새로 바인딩하면 덮어씀
resource "databricks_mws_ncc_binding" "this" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
  workspace_id                   = azurerm_databricks_workspace.this.workspace_id
}

# apply 후 SA에 pending 연결 생성 → 소유자 승인 필요. dfs·blob 둘 다 필요한 건 storage.tf PE와 동일
resource "databricks_mws_ncc_private_endpoint_rule" "adls_dfs" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
  resource_id                    = azurerm_storage_account.adls.id
  group_id                       = "dfs"
}

resource "databricks_mws_ncc_private_endpoint_rule" "adls_blob" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
  resource_id                    = azurerm_storage_account.adls.id
  group_id                       = "blob"
}

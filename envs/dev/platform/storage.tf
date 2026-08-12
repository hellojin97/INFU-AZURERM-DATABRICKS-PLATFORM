# SA 이름 규칙은 다른 리소스와 다르다. 소문자·숫자만, 하이픈 불가, 3~24자, 전역 유일.
resource "azurerm_storage_account" "adls" {
  name                = lower("${var.prefix}${var.env}adls${var.location_abbreviation}")
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # ADLS Gen2 스위치. 계층 네임스페이스를 켜며 생성 후 변경 불가.
  is_hns_enabled = true

  # 공용 접근구를 아예 닫는다. 접근은 Private Endpoint로만 한다.
  public_network_access_enabled = false

  # state SA와 같은 원칙. 공유 키 대신 Entra ID 인증만 허용한다.
  shared_access_key_enabled = false

  tags = local.tags
}

# PE 하나가 subresource 하나를 맡는다. ADLS는 dfs와 blob 둘 다 필요해 PE도 두 개다.
# RG는 network다. PE와 그 NIC는 네트워크 객체라 서브넷과 같은 곳에 둔다.
resource "azurerm_private_endpoint" "adls_dfs" {
  name                = "${local.name_prefix}-ADLS-DFS-PE-${local.location_abbreviation}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.privatelink.id

  # "무엇에 연결하나". 대상 리소스 ID + subresource. 같은 테넌트라 자동 승인(is_manual_connection = false).
  private_service_connection {
    name                           = "${local.name_prefix}-ADLS-DFS-PSC-${local.location_abbreviation}"
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  # PE의 사설 IP를 해당 영역에 A 레코드로 자동 등록한다. 없으면 IP를 수동 관리해야 한다.
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.dfs.id]
  }

  tags = local.tags
}

resource "azurerm_private_endpoint" "adls_blob" {
  name                = "${local.name_prefix}-ADLS-BLOB-PE-${local.location_abbreviation}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.privatelink.id

  private_service_connection {
    name                           = "${local.name_prefix}-ADLS-BLOB-PSC-${local.location_abbreviation}"
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = local.tags
}

# ---------------- ACCESS CONNECTOR ---------------- #

# Databricks가 쓰는 managed identity 껍데기. UC storage credential이 이 identity로 ADLS에 접근한다.
resource "azurerm_databricks_access_connector" "this" {
  name                = "${local.name_prefix}-DATABRICKS-AC-${local.location_abbreviation}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  # SystemAssigned = Azure가 identity를 만들어 리소스에 붙인다. 수명도 리소스와 같다.
  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# scope를 SA 하나로 좁힌다. RG 전체가 아니라 이 스토리지만.
# 이 리소스 생성에 CI SP의 User Access Administrator 권한이 쓰인다.
resource "azurerm_role_assignment" "adls_connector" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"

  # identity는 list 속성이라 [0]으로 꺼낸다.
  principal_id = azurerm_databricks_access_connector.this.identity[0].principal_id
}

# HNS SA에서 container = ADLS filesystem. catalog managed storage 용도.
# storage_account_id 지정 시 Resource Manager API 사용.
# data-plane 리소스(storage_data_lake_gen2_filesystem)는 public access 차단 SA라 403.
resource "azurerm_storage_container" "managed" {
  name               = "managed"
  storage_account_id = azurerm_storage_account.adls.id
}

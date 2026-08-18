# 실행 주체(CI SP)의 테넌트·구독 정보 읽기 전용 조회. 리소스 생성 없음
data "azurerm_client_config" "current" {}

# Databricks App(다른 레포)용 DB. Lakebase 대신 Azure PaaS 채택
# delegated subnet 미사용 = public access + PE 모델. 생성 후 모델 변경 불가
resource "azurerm_postgresql_flexible_server" "this" {
  # PG 서버 이름 규칙은 SA와 유사하게 별도: 소문자·숫자·하이픈만, 3~63자
  name                = lower("${local.name_prefix}-pg-${local.location_abbreviation}")
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  # password_auth_enabled = true면 native admin 필수 (apply 시점 검사라 validate로 못 잡음)
  # 사람은 Entra admin으로 접속. 이 계정은 생성 요건 충족용, 자격 증명 배포 안 함
  administrator_login    = "pgadmin"
  administrator_password = random_password.pg_admin.result

  # B_Standard_B1ms = Burstable 최소 SKU. dev 전용, 병목 시 SKU만 교체
  version  = "16"
  sku_name = "B_Standard_B1ms"

  # storage_mb 32768 = 허용 최소값. 축소 불가, 확장만 가능
  # zone 미지정 시 Azure 임의 배치 → plan drift. 고정해 둠
  storage_mb                    = 32768
  backup_retention_days         = 7
  zone                          = "1"
  public_network_access_enabled = false

  # 인증 병행: Entra = admin(사람·CI), password = 앱 전용 DB user
  # 앱 SP는 Databricks 관리 SP라 Entra 토큰 발급 불가 → 앱은 password 경로
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = local.tags
}

# admin은 운영자 개인 Entra 계정. 팀 확장 시 그룹으로 교체(변수 값 + principal_type만 변경)
# 앱 user CREATE ROLE은 이 admin으로 접속해 수동 실행
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = var.pg_admin_object_id
  principal_name      = var.pg_admin_principal_name
  principal_type      = "User"
}

# 이름은 Azure 고정 문자열. dfs/blob zone과 같은 구조
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                = "${local.name_prefix}-PG-DNS-LINK-${local.location_abbreviation}"
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  virtual_network_id  = azurerm_virtual_network.this.id
  tags                = local.tags
}

# PG는 subresource가 postgresqlServer 하나라 PE도 1개. ADLS(dfs·blob 2개)와 대비
resource "azurerm_private_endpoint" "postgres" {
  name                = "${local.name_prefix}-PG-PE-${local.location_abbreviation}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.privatelink.id

  private_service_connection {
    name                           = "${local.name_prefix}-PG-PSC-${local.location_abbreviation}"
    private_connection_resource_id = azurerm_postgresql_flexible_server.this.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgres.id]
  }

  tags = local.tags
}

# 값은 state에만 존재. special 제외 = 연결 문자열 이스케이프 문제 예방
resource "random_password" "pg_admin" {
  length  = 24
  special = false
}
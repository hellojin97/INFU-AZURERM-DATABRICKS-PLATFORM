# alias 없음 = 기본 provider. azurerm 리소스가 자동으로 이걸 쓴다
provider "azurerm" {
  # 필수 블록. 비어 있어도 선언 자체는 있어야 함
  features {}

  # 인증 인자 없음. 워크플로가 ARM_CLIENT_ID / ARM_TENANT_ID / ARM_SUBSCRIPTION_ID / ARM_USE_OIDC 주입
  # azurerm 4.x부터 subscription_id 필수 → ARM_SUBSCRIPTION_ID로 충족
}

# databricks_metastore_assignment 전용. workspace 내부용 provider는 4단계 소관
provider "databricks" {
  # alias 있으면 기본 provider 아님. 쓰는 쪽에서 provider = databricks.account 명시 필요
  alias = "account"

  # account 레벨 엔드포인트. Azure는 이 주소로 고정
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id

  # azure/login@v2가 남긴 az CLI 세션 사용. github-oidc-azure는 audience 미지정으로 실패
  auth_type = "azure-cli"

  azure_client_id = var.azure_client_id
  azure_tenant_id = var.azure_tenant_id
}

resource "azurerm_databricks_workspace" "this" {
  name                = "${local.name_prefix}-DATABRICKS-WS-${local.location_abbreviation}"
  resource_group_name = azurerm_resource_group.databricks.name
  location            = azurerm_resource_group.databricks.location

  # premium 전용 기능이 있다. Unity Catalog, cluster policy, 권한 ACL이 여기 속한다.
  sku = "premium"

  # Databricks가 클러스터용 리소스를 넣을 리소스 그룹. Terraform이 아니라 Databricks가 만든다.
  managed_resource_group_name = "${local.name_prefix}-DATABRICKS-MANAGED-RG-${local.location_abbreviation}"

  # 인자가 아니라 중첩 블록이다. VNet injection 설정을 여기 모은다.
  custom_parameters {
    virtual_network_id = azurerm_virtual_network.this.id

    no_public_ip = true

    public_subnet_name  = azurerm_subnet.public.name
    private_subnet_name = azurerm_subnet.private.name

    # 서브넷 ID가 아니라 NSG 연결 리소스의 ID다. 이 참조가 연결을 workspace보다 먼저 만들게 한다.
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }

  tags = local.tags
}

# data 블록은 읽기 전용이다. 만들지 않고 이미 있는 값을 가져온다.
# 라벨 두 개는 타입과 로컬 이름이며 data.<타입>.<로컬 이름>으로 참조한다.
data "terraform_remote_state" "account" {
  backend = "azurerm"

  # root의 backend 블록에서 아무것도 물려받지 않아 값을 전부 다시 적는다.
  # account/backend.hcl과 같은 값이어야 그 state 파일을 찾는다.
  config = {
    resource_group_name  = "INFU-TFSTATE-RG-CAC"
    storage_account_name = "infutfstateblobcac"
    container_name       = "tfstate"
    key                  = "account.tfstate"

    # 대응 환경 변수 ARM_USE_AZUREAD를 워크플로가 설정하지 않아 여기 적어야 한다.
    use_azuread_auth = true

    # ARM_USE_OIDC가 이미 설정되어 있다. 생략해도 되지만 명시해 둔다.
    use_oidc = true
  }
}

resource "databricks_metastore_assignment" "this" {
  # alias가 붙은 provider는 기본이 아니므로 쓰는 쪽에서 지목한다.
  provider = databricks.account

  # .outputs.<이름>으로 다른 계층의 output 블록 값을 읽는다.
  metastore_id = data.terraform_remote_state.account.outputs.metastore_id

  # Azure 리소스 ID가 아니라 Databricks 제어 평면의 숫자 ID다.
  workspace_id = azurerm_databricks_workspace.this.workspace_id
}

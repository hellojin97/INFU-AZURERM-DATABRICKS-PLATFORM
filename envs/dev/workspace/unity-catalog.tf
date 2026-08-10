# workspace를 통해 만들지만 metastore 소속 객체다. 같은 metastore의 workspace들이 공유할 수 있다.
# 만든 주체(CI SP)가 owner가 된다.
resource "databricks_storage_credential" "adls" {
  name = "${local.name_prefix}-ADLS-CREDENTIAL"

  # Databricks와 Access Connector의 연결 지점. Azure 쪽 권한(role assignment)은 platform 계층이 이미 붙였다.
  azure_managed_identity {
    access_connector_id = data.terraform_remote_state.platform.outputs.access_connector_id
  }

  comment = "Access Connector의 managed identity로 ADLS에 접근하는 자격 증명"
}

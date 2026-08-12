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

# credential에 "이 경로를 이 자격 증명으로" 범위를 부여. catalog managed location이 참조할 대상.
# url 형식: abfss://<container>@<sa>.dfs.core.windows.net/
resource "databricks_external_location" "managed" {
  credential_name = databricks_storage_credential.adls.name
  name            = "${local.name_prefix}-MANAGED-LOCATION"
  url             = "abfss://${data.terraform_remote_state.platform.outputs.managed_container_name}@${data.terraform_remote_state.platform.outputs.adls_storage_account_name}.dfs.core.windows.net/"
}

# grants는 객체당 하나. 여기 없는 grant는 apply 때 제거된다 (owner 권한은 별개).
# BROWSE만: managed storage 영역이라 파일 직접 접근 권한은 주지 않는다.
resource "databricks_grants" "managed_location" {
  external_location = databricks_external_location.managed.id

  grant {
    principal  = "${local.name_prefix}-WS-ADMINS"
    privileges = ["BROWSE"]
  }
}

# name: SQL 식별자라 언더스코어. env로 환경 구분
# storage_root: managed table 저장 경로
# ISOLATED: 현재 workspace만 바인딩. 기본 OPEN = 전 workspace 노출
resource "databricks_catalog" "this" {
  name           = "${var.prefix}_${var.env}"
  storage_root   = databricks_external_location.managed.url
  isolation_mode = "ISOLATED"
  comment        = "개발 환경 기본 카탈로그"
}

resource "databricks_grants" "catalog" {
  catalog = databricks_catalog.this.name

  grant {
    principal  = "${local.name_prefix}-WS-ADMINS"
    privileges = ["ALL_PRIVILEGES", "READ_METADATA"]
  }
}

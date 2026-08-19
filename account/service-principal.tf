# app 저장소 DAB 배포용. Azure 리소스 안 만들어 Entra SP 불필요
resource "databricks_service_principal" "app_deploy" {
  provider     = databricks.account
  display_name = upper("${var.prefix}-DAB-GITHUB-ACTIONS")
}

# GitHub Actions 토큰 직접 신뢰. 저장할 secret 없음
# .id는 SCIM ID 문자열, 인자는 integer라 tonumber 필요
resource "databricks_service_principal_federation_policy" "app_deploy" {
  provider             = databricks.account
  service_principal_id = tonumber(databricks_service_principal.app_deploy.id)

  # jwks 미지정: well-known endpoint에서 공개키 자동 조회
  # subject는 완전 일치. 값 바뀌는 ref 대신 고정된 environment 사용, 배포 job이 environment: dev 선언해야 인증
  oidc_policy = {
    issuer    = "https://token.actions.githubusercontent.com"
    audiences = ["https://adb-7405605204277280.0.azuredatabricks.net/oidc/v1/token"]
    subject   = "repo:hellojin97@96719728/INFU-DAB-DATABRICKS-APP@1339704553:environment:dev"
  }
}
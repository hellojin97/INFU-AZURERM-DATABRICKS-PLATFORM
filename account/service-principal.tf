# app 저장소(INFU-DAB-DATABRICKS-APP)의 DAB 배포 전용 SP
# Entra SP가 아니라 Databricks account SP다. Azure 리소스를 만들지 않아 Entra 등록이 필요 없다
resource "databricks_service_principal" "app_deploy" {
  provider     = databricks.account
  display_name = upper("${var.prefix}-DAB-GITHUB-ACTIONS")
}

# OIDC token federation. GitHub Actions 토큰을 그대로 신뢰해 secret 저장이 없다
# .id는 SCIM 내부 ID(문자열)라 integer 인자에 맞추려면 tonumber가 필요하다
resource "databricks_service_principal_federation_policy" "app_deploy" {
  provider             = databricks.account
  service_principal_id = tonumber(databricks_service_principal.app_deploy.id)

  # jwks_uri·jwks_json 미지정: Databricks가 issuer well-known endpoint에서 공개키를 자동 조회한다
  # subject는 완전 일치라 와일드카드가 없다. 태그마다 값이 바뀌는 ref 대신 값이 고정된 environment를 쓴다
  # 그래서 app 저장소 배포 job은 environment: dev를 선언해야 인증된다
  oidc_policy = {
    issuer    = "https://token.actions.githubusercontent.com"
    audiences = ["https://github.com/hellojin97"]
    subject   = "repo:hellojin97/INFU-DAB-DATABRICKS-APP:environment:dev"
  }
}
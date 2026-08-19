# Databricks-backed scope. Key Vault-backed는 생성에 user AAD token 필요해 OIDC SP로 불가
# UC secret이 방향에 더 맞지만 provider 미지원(1.128.0 기준). 나오면 이전
# 그릇만 Terraform 소유. 값은 CLI로 주입해 state·tfvars에 password 남기지 않음
resource "databricks_secret_scope" "app" {
  name = "${var.prefix}-${var.env}-app"
}
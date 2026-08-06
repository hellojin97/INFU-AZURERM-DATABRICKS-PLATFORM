# provider 블록: provider의 접속·인증 설정. 라벨("databricks")이 provider 로컬 이름이다.
provider "databricks" {
  # alias: 같은 provider를 여러 설정으로 쓸 때 붙이는 이름표.
  # alias가 붙으면 기본 provider가 아니게 되어, 쓰는 쪽에서 반드시 지목해야 한다.
  alias = "account"

  # 접속할 API 엔드포인트. account 레벨은 Azure에서 이 주소로 고정이다.
  host = "https://accounts.azuredatabricks.net"

  # var.<이름>으로 variable 블록에 선언된 값을 참조한다.
  account_id = var.databricks_account_id

  # 인증 방식 선택. GitHub OIDC 토큰을 Entra ID 토큰으로 교환한다.
  # Actions 런타임 환경 변수를 읽으므로 로컬에서는 인증되지 않는다.
  auth_type = "github-oidc-azure"

  azure_client_id = var.azure_client_id
  azure_tenant_id = var.azure_tenant_id
}

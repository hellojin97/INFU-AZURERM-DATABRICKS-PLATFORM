# resource 블록: 실제로 생성·변경·삭제할 대상. 라벨 두 개는 타입과 로컬 이름이다.
# Unity Catalog metastore는 리전당 하나만 존재할 수 있어 환경별로 나누지 않는다.
# 환경 분리는 이 metastore 안의 카탈로그로 한다.
resource "databricks_metastore" "this" {
  provider = databricks.account

  # ${...}는 문자열 안에 식을 끼워 넣는 보간 문법이다.
  # metastore 이름은 계정 전체에서 유일해야 하므로 접두사를 붙인다.
  name = upper("${var.prefix}-uc-metastore-${var.location_abbreviation}")

  # 계정 레벨 metastore에서는 필수다.
  region = var.location

  # storage_root를 지정하지 않는다. 카탈로그마다 스토리지를 따로 두는 방식이다.
  # force_destroy도 지정하지 않는다. 기본값 false라 카탈로그가 있으면 destroy가 실패한다.

  # owner: 콘솔 수동 생성 그룹. CI SP가 멤버여야 Terraform이 metastore 수정 가능
  owner = upper("${var.prefix}-metastore-${var.location_abbreviation}-admins")
}

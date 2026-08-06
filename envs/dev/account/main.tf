# data 블록: 기존 대상을 읽기만 한다. 생성·변경·삭제하지 않는다.
# 라벨 두 개 중 앞이 data source 타입, 뒤가 이 블록에 붙이는 로컬 이름이다.
# 다른 곳에서는 data.databricks_metastores.all.<속성>으로 참조한다.
data "databricks_metastores" "all" {
  # provider 메타 인자: 어느 provider 설정을 쓸지 지목한다.
  # alias가 붙은 provider는 <provider이름>.<alias> 형태로 명시해야 한다.
  provider = databricks.account
}

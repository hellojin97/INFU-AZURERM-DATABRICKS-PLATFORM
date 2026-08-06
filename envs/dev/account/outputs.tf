# output 블록: apply 후 화면에 표시하고, 다른 계층이 remote state로 읽을 수 있게 한다.
# 라벨이 출력 이름이며 terraform output <이름>으로 조회한다.
output "metastore_ids" {
  # value: 내보낼 식. data.<타입>.<로컬이름>.<속성> 형태로 data 블록의 결과를 참조한다.
  value = data.databricks_metastores.all.ids

  # description: 용도 설명. terraform output 목록에는 나오지 않고 문서화용이다.
  description = "account에 등록된 metastore 목록"
}

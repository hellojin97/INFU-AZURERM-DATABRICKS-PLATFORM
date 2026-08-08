# output 블록: apply 후 표시하고, 다른 계층이 remote state로 읽을 수 있게 한다.
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "Unity Catalog metastore ID. platform 계층이 metastore assignment에 사용한다."
}

# for_each로 만든 리소스는 map이 되므로, 키를 유지한 채 값만 바꿔 내보낸다.
output "uc_admins_group_ids" {
  value       = { for env, g in databricks_group.uc_admins : env => g.id }
  description = "환경별 Unity Catalog 관리 그룹 ID"
}

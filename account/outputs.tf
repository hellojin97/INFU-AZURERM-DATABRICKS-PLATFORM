# output 블록: apply 후 표시하고, 다른 계층이 remote state로 읽을 수 있게 한다.
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "Unity Catalog metastore ID. platform 계층이 metastore assignment에 사용한다."
}

# for_each로 만든 리소스는 map이 되므로, 키를 유지한 채 값만 바꿔 내보낸다.
output "workspace_admin_group_ids" {
  value       = { for env, g in databricks_group.workspace_admin_group : env => g.id }
  description = "환경별 workspace 관리자 그룹 ID. platform 계층이 workspace 바인딩에 사용한다."
}

output "workspace_user_group_ids" {
  value       = { for env, g in databricks_group.workspace_user_group : env => g.id }
  description = "환경별 workspace 사용자 그룹 ID"
}
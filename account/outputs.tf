# output 블록: apply 후 표시하고, 다른 계층이 remote state로 읽을 수 있게 한다.
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "Unity Catalog metastore ID. platform 계층이 metastore assignment에 사용한다."
}
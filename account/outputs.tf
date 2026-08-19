# output 블록: apply 후 표시하고, 다른 계층이 remote state로 읽을 수 있게 한다.
output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "Unity Catalog metastore ID. platform 계층이 metastore assignment에 사용한다."
}

output "app_deploy_sp_application_id" {
  value       = databricks_service_principal.app_deploy.application_id
  description = "app 저장소 배포용 SP의 client ID. app 저장소 repository variable로 등록한다."
}
# GUID 3개는 TF_VAR_ 환경 변수로 주입한다. 저장소가 public이라 tfvars에 넣지 않는다.
# sensitive를 붙이면 공개되는 plan 출력에 (sensitive value)로 찍힌다.

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID"
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  description = "CI Service Principal의 Entra ID 애플리케이션 ID"
  sensitive   = true
}

variable "azure_tenant_id" {
  type        = string
  description = "Entra ID 테넌트 ID"
  sensitive   = true
}

# 아래는 terraform.tfvars로 주입한다.

variable "prefix" {
  type        = string
  description = "리소스 이름 접두사"
}

variable "location" {
  type        = string
  description = "metastore를 만들 Azure 리전. 리전당 metastore는 하나만 존재할 수 있다."
}

variable "location_abbreviation" {
  type        = string
  description = "metastore를 만들 Azure 리전의 약어."
}

# owner 태그 변수는 이 계층에 두지 않는다.
# Databricks 리소스에는 Azure 태그가 없어 쓸 곳이 없고,
# databricks_metastore의 owner는 태그가 아니라 소유 principal이라 의미가 다르다.
# 태그는 Azure 리소스를 만드는 envs/<env>/platform/ 에서 선언한다.

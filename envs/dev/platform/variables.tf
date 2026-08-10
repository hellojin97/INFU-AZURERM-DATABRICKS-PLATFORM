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

variable "prefix" {
  type        = string
  description = "리소스 이름 접두사"
}

variable "env" {
  type        = string
  description = "환경 이름"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "env는 dev, stg, prd 중 하나여야 합니다."
  }
}

variable "location" {
  type        = string
  description = "Azure 리전"
}

variable "location_abbreviation" {
  type        = string
  description = "Azure 리전 약어"
}

variable "owner" {
  type        = string
  description = "소유자 태그 값"
}

variable "vnet_cidr" {
  type        = string
  description = "VNet 주소 공간"
}

variable "subnet_public_cidr" {
  type        = string
  description = "Databricks public(host) 서브넷 주소 범위"
}

variable "subnet_private_cidr" {
  type        = string
  description = "Databricks private(container) 서브넷 주소 범위"
}

variable "subnet_privatelink_cidr" {
  type        = string
  description = "Private Endpoint 전용 서브넷 주소 범위"
}

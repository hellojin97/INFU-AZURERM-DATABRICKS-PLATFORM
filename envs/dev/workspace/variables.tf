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

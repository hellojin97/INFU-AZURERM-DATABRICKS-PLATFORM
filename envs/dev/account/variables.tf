# variable 블록: 이 모듈의 입력값을 선언한다. 라벨이 변수 이름이 되고 var.<이름>으로 참조한다.
# 값 주입 우선순위는 CLI -var > -var-file > TF_VAR_ 환경 변수 > default 순이다.

variable "databricks_account_id" {
  # type: 허용할 값의 형태. string / number / bool / list() / map() / object() 등.
  type = string

  # description: 용도 설명. terraform 명령이 값을 물어볼 때도 표시된다.
  description = "Databricks account ID"

  # sensitive: 값을 plan·apply 출력에서 (sensitive value)로 가린다.
  # default가 없으므로 이 변수는 필수다. 주지 않으면 실행이 멈춘다.
  sensitive = true
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

variable "env" {
  type        = string
  description = "환경 이름"

  # validation 블록: 값이 조건을 통과하지 못하면 plan 단계에서 실패시킨다.
  validation {
    # condition은 true/false를 내는 식. contains(리스트, 값)은 포함 여부를 본다.
    # 자기 자신을 var.env로 참조하는 것이 규칙이다.
    condition = contains(["dev", "stg", "prd"], var.env)

    # 조건이 false일 때 출력할 메시지.
    error_message = "env는 dev, stg, prd 중 하나여야 합니다."
  }
}

variable "prefix" {
  type        = string
  description = "리소스 이름 접두사"
}

variable "location" {
  type        = string
  description = "Azure 리전. 리전당 metastore는 하나만 존재할 수 있다."
}

variable "owner" {
  type        = string
  description = "소유자 태그 값"
}

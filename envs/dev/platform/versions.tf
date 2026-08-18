# terraform 블록: Terraform 자체 동작 설정. 변수·함수 사용 불가
terraform {
  # 실행 가능한 Terraform 버전 범위
  required_version = ">= 1.15"

  # 사용할 provider 선언. 왼쪽 키(azurerm) = 이 모듈 내 로컬 이름
  required_providers {
    azurerm = {
      # Registry 주소. <네임스페이스>/<이름>
      source = "hashicorp/azurerm"

      # ~> = 마지막 자리만 상향 허용. 5.0 → >= 5.0.0, < 6.0.0
      version = "~> 5.0"
    }

    # databricks_metastore_assignment 용. account 레벨 리소스지만 workspace ID 필요
    databricks = {
      source = "databricks/databricks"

      # account 계층과 동일 버전. 계층별 버전 차이 = 동작 차이
      version = "~> 1.124"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # backend 블록: state 저장 위치. 라벨(azurerm) = backend 종류
  # 빈 블록 = partial configuration. 값은 init -backend-config= 로 주입
  backend "azurerm" {}
}

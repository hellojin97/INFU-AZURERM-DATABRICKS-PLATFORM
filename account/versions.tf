# terraform 블록: Terraform 자체의 동작을 설정한다. 변수나 함수를 쓸 수 없다.
terraform {
  # 이 코드를 실행할 수 있는 Terraform 버전 범위.
  required_version = ">= 1.15"

  # 필요한 provider를 선언한다. 왼쪽 키(databricks)가 이 모듈에서 쓸 로컬 이름이 된다.
  required_providers {
    databricks = {
      # Terraform Registry 주소. <네임스페이스>/<이름> 형식.
      source = "databricks/databricks"

      # ~> 는 마지막 자리만 올려받는 연산자. 1.124면 >= 1.124.0, < 1.125.0.
      version = "~> 1.124"
    }
    # 선언하지 않은 provider는 쓸 수 없다. 이 계층은 Azure 리소스를 만들지 않는다.
  }

  # backend 블록: state 저장 위치. 라벨(azurerm)이 backend 종류다.
  # 빈 블록은 partial configuration이며, 값은 init -backend-config= 로 주입한다.
  backend "azurerm" {}
}

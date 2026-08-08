# backend "azurerm" {} 빈 블록에 주입할 값. terraform init -backend-config=backend.hcl 로 넘긴다.
# 블록 없이 키 = 값만 나열한다. 변수나 함수는 쓸 수 없다.

resource_group_name  = "INFU-TFSTATE-RG-CAC"
storage_account_name = "infutfstateblobcac"
container_name       = "tfstate"

# key: 컨테이너 안에서의 state 파일 경로.
# Databricks account는 테넌트당 하나뿐이라 환경 접두사를 붙이지 않는다.
key = "account.tfstate"

# 스토리지 계정 키 액세스를 껐으므로 Entra ID로 인증한다.
use_azuread_auth = true

# GitHub OIDC 토큰으로 인증한다. 신원은 ARM_* 환경 변수로 들어온다.
use_oidc = true

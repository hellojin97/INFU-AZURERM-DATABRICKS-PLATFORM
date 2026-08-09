# locals 블록: 이 모듈 안에서만 쓰는 이름 붙인 값. local.<이름>으로 참조한다.
locals {
  # upper()는 문자열을 대문자로 바꾸는 내장 함수다. ${...}는 문자열 안에 식을 끼워 넣는 보간 문법.
  name_prefix           = upper("${var.prefix}-${var.env}")
  location_abbreviation = upper(var.location_abbreviation)

  # 중괄호는 map이다. 키는 따옴표 없이 쓸 수 있다.
  tags = {
    env        = var.env
    owner      = var.owner
    managed_by = "terraform"
  }

  # 여러 곳에서 같은 값을 쓸 때 locals에 한 번만 적는다.
  databricks_subnet_actions = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
  ]
}

# resource 블록의 라벨 두 개는 타입과 로컬 이름이다. 로컬 이름은 코드 안에서만 쓰는 주소다.
resource "azurerm_resource_group" "network" {
  name     = "${local.name_prefix}-NETWORK-RG-${local.location_abbreviation}"
  location = var.location
  tags     = local.tags
}

# 타입이 같아도 로컬 이름이 다르면 별개 리소스다.
resource "azurerm_resource_group" "databricks" {
  name     = "${local.name_prefix}-DATABRICKS-RG-${local.location_abbreviation}"
  location = var.location
  tags     = local.tags
}

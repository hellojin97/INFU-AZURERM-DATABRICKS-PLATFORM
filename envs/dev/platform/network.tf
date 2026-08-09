resource "azurerm_virtual_network" "this" {
  name = "${local.name_prefix}-DATABRICKS-VNET-${local.location_abbreviation}"

  # <타입>.<로컬 이름>.<속성>으로 다른 리소스를 참조한다. 참조는 곧 실행 순서 의존이다.
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location

  # 대괄호는 list다. 이 인자는 값 하나여도 list를 받는다.
  address_space = [var.vnet_cidr]

  tags = local.tags
}

resource "azurerm_subnet" "public" {
  name                 = "${local.name_prefix}-DATABRICKS-PUBLIC-SNET-${local.location_abbreviation}"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name

  # 인자 이름이 복수형이면 list를 받는다.
  address_prefixes = [var.subnet_public_cidr]

  # 인자가 아니라 중첩 블록이다. = 없이 이름 뒤에 바로 중괄호를 연다.
  delegation {
    # 위임 항목에 붙이는 임의 라벨. 아래 서비스 이름과는 무관하다.
    name = "databricks"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = local.databricks_subnet_actions
    }
  }
}

resource "azurerm_subnet" "private" {
  name                 = "${local.name_prefix}-DATABRICKS-PRIVATE-SNET-${local.location_abbreviation}"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_private_cidr]

  delegation {
    name = "databricks"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = local.databricks_subnet_actions
    }
  }
}

# security_rule 블록을 두지 않는다. workspace 생성 시 Databricks가 규칙을 직접 넣기 때문이다.
resource "azurerm_network_security_group" "this" {
  name                = "${local.name_prefix}-DATABRICKS-NSG-${local.location_abbreviation}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

# 자체 속성 없이 두 리소스를 잇기만 하는 리소스다. 이름도 태그도 받지 않는다.
resource "azurerm_subnet_network_security_group_association" "public" {
  # 지금까지 .name을 참조했지만 여기서는 전체 리소스 ID인 .id를 받는다.
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.this.id
}
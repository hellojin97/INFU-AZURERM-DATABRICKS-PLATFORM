# serverless egress 방화벽. RESTRICTED_ACCESS = 허용 목록 밖 outbound 차단
# 중첩 블록 아닌 = 객체 문법. NCC 리소스와 다름
resource "databricks_account_network_policy" "this" {
  provider          = databricks.account
  network_policy_id = "infu-dev-network-policy"

  # 생략 시 computed라 변경 때마다 unknown 처리되어 replace 유발. 명시해 in-place update 유지
  account_id = var.databricks_account_id

  egress = {
    network_access = {
      restriction_mode = "RESTRICTED_ACCESS"

      allowed_internet_destinations = [
        {
          destination               = "pypi.org"
          internet_destination_type = "DNS_NAME"
        },
        {
          # 패키지 다운로드 호스트. pypi.org만으론 설치 실패
          destination               = "files.pythonhosted.org"
          internet_destination_type = "DNS_NAME"
        },
        {
          # PE rule ESTABLISHED여도 DNS 필터 허용 목록은 별개. 등록해야 해석되고, 해석 결과가 사설 IP라 트래픽은 PE 경유
          destination               = azurerm_postgresql_flexible_server.this.fqdn
          internet_destination_type = "DNS_NAME"
        }
      ]

      policy_enforcement = {
        enforcement_mode = "ENFORCED"
      }
    }
  }
}

# 미지정 시 default-policy(full access). workspace당 policy 하나
resource "databricks_workspace_network_option" "this" {
  provider          = databricks.account
  workspace_id      = azurerm_databricks_workspace.this.workspace_id
  network_policy_id = databricks_account_network_policy.this.network_policy_id
}

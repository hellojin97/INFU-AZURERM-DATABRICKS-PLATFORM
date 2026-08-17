# 리소스 타입은 레거시 명칭 databricks_sql_endpoint. databricks_sql_warehouse는 data source 전용
# warehouse_type PRO + enable_serverless_compute = serverless. "Serverless"는 유효값이 아니다
resource "databricks_sql_endpoint" "default" {
  name             = "${var.prefix}-${var.env}-sqlwh-2xsmall"
  cluster_size     = "2X-Small"
  min_num_clusters = 1
  max_num_clusters = 1
  auto_stop_mins   = 15
  warehouse_type   = "PRO"

  enable_serverless_compute = true
  enable_photon             = true

  tags {
    custom_tags {
      key   = "ServiceName"
      value = "sqlwh"
    }
    custom_tags {
      key   = "Organization"
      value = "infu-da"
    }
    custom_tags {
      key   = "Purpose"
      value = "adhoc"
    }
    custom_tags {
      key   = "Region"
      value = "cac"
    }
  }
}

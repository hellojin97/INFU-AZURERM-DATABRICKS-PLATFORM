data "databricks_sql_warehouse" "default" {
  name = "${var.prefix}-${var.env}-sqlwh-2xsmall"

  cluster_size     = "2X-Small"
  min_num_clusters = 1
  max_num_clusters = 1
  auto_stop_mins   = 15
  warehouse_type   = "Serverless"

  tags {
    ServiceName  = "sqlwh"
    Organization = "infu-da"
    Purpose      = "adhoc"
    Region       = "cac"
  }

  enable_serverless_compute = true
  enable_photon             = true
}
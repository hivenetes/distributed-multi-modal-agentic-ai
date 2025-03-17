# Add random suffix generator
resource "random_id" "db_suffix" {
  byte_length = 4
}

locals {
  database_cluster_name = "${var.database_cluster_name_prefix}-${var.database_cluster_engine}-${join("-", var.regions)}"
}

# # https://docs.digitalocean.com/reference/terraform/reference/resources/database_cluster/
# resource "digitalocean_database_cluster" "hive-db" {
#     name       = local.database_cluster_name
#     engine     = var.database_cluster_engine
#     version    = var.database_cluster_version
#     region     = var.database_cluster_region
#     size       = var.database_cluster_size
#     node_count = var.database_cluster_node_count
# }

# Create database clusters in each region
resource "digitalocean_database_cluster" "regional" {
  count      = length(var.regions) # Ensure this is set to 3 for three regions
  name       = "${var.database_cluster_name_prefix}-${var.database_cluster_engine}-${var.regions[count.index]}-${random_id.db_suffix.hex}"
  engine     = var.database_cluster_engine
  version    = var.database_cluster_version
  region     = var.regions[count.index]
  size       = var.database_cluster_size
  node_count = var.database_cluster_node_count
}


resource "random_id" "space_suffix" {
  byte_length = 4
  
  lifecycle {
    prevent_destroy = false
  }
}

resource "digitalocean_spaces_bucket" "regional" {
  count  = length(var.regions)
  name   = "${var.space_name_prefix}-${var.regions[count.index]}-${random_id.space_suffix.hex}"
  region = var.regions[count.index]
  
  # lifecycle {
  #   prevent_destroy = false
  #   # Prevent changes that require recreation
  #   ignore_changes = [
  #     name,
  #     region
  #   ]
  # }
}

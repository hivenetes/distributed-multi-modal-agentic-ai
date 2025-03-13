resource "random_id" "space_suffix" {
  byte_length = 4
}

resource "digitalocean_spaces_bucket" "regional" {
  count  = length(var.regions)
  name   = "${var.space_name_prefix}-${var.regions[count.index]}-${random_id.space_suffix.hex}"
  region = var.regions[count.index]
}

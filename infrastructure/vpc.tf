# Create VPCs in each region with unique CIDR blocks
resource "digitalocean_vpc" "regional" {
  count       = length(var.regions)
  name        = "${var.project_name}-vpc-${var.regions[count.index]}"
  region      = var.regions[count.index]
  description = "VPC for ${var.project_name} in ${var.regions[count.index]}"
  ip_range    = "10.${count.index + 1}.0.0/16" # Each region gets a unique /16 CIDR block
}

# resource "digitalocean_vpc_peering" "regional" {
#   count = length(var.regions) * (length(var.regions) - 1) / 2 # Calculate number of unique pairs
#   name  = "${var.project_name}-peering-${count.index}"
#   vpc_ids = [
#     digitalocean_vpc.regional[floor(count.index / (length(var.regions) - 1))].id,
#     digitalocean_vpc.regional[count.index % (length(var.regions) - 1) + (floor(count.index / (length(var.regions) - 1)) <= count.index % (length(var.regions) - 1) ? 1 : 0)].id
#   ]
#   lifecycle {
#     prevent_destroy = true # Allow ignoring existing VPC peering
#   }
# }
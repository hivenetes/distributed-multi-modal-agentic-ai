# Create droplets in each region
resource "digitalocean_droplet" "web" {
  count  = length(var.regions) # 1 droplet per region
  name   = "web-${var.regions[count.index]}-1"
  size   = var.droplet_size
  image  = var.droplet_image
  region = var.regions[count.index]
  #   ssh_keys = [digitalocean_ssh_key.default.fingerprint] TODO

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Welcome to Hivenetes - Region: ${var.regions[count.index]} - Droplet: 1</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = ["web", "region:${var.regions[count.index]}"]
}

# Create regional load balancers
resource "digitalocean_loadbalancer" "regional" {
  count  = length(var.regions)
  name   = "lb-regional-${var.regions[count.index]}"
  region = var.regions[count.index]

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  # Select droplet in the current region
  droplet_ids = [digitalocean_droplet.web[count.index].id]
}

# Create domain (changed from resource to data source)
data "digitalocean_domain" "default" {
  name = var.domain
}

# Create global load balancer
# resource "digitalocean_record" "global_lb" {
#   domain = digitalocean_domain.default.name
#   type   = "A"
#   name   = "@"
#   value  = digitalocean_loadbalancer.regional[0].ip
#   ttl    = 300
# }

resource "digitalocean_loadbalancer" "glb1" {
  name = "hb-glb-tf"
  type = "GLOBAL"
  domains {
    name       = data.digitalocean_domain.default.name
    is_managed = true
  }
  glb_settings {
    target_protocol = "http"
    target_port     = 80
    cdn {
      is_enabled = true
    }
  }
  target_load_balancer_ids = [
    for lb in digitalocean_loadbalancer.regional : lb.id
  ]
}

# Add CNAME records for each region
resource "digitalocean_record" "regional_cname" {
  count  = length(var.regions)
  domain = data.digitalocean_domain.default.name
  type   = "CNAME"
  name   = var.regions[count.index]
  value  = "${var.domain}."
  ttl    = 300
}

# Add all resources to the project
resource "digitalocean_project_resources" "all" {
  project = digitalocean_project.project.id
  resources = concat(
    [for droplet in digitalocean_droplet.web : droplet.urn],
    [for lb in digitalocean_loadbalancer.regional : lb.urn],
    [digitalocean_loadbalancer.glb1.urn],
    [data.digitalocean_domain.default.urn],
    [for space in digitalocean_spaces_bucket.regional : space.urn],
    [for db in digitalocean_database_cluster.regional : db.urn]
  )
}
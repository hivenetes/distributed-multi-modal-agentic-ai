output "droplet_ips" {
  value = {
    for droplet in digitalocean_droplet.web :
    droplet.name => droplet.ipv4_address
  }
}

output "regional_lb_ips" {
  value = {
    for lb in digitalocean_loadbalancer.regional :
    lb.name => lb.ip
  }
}

output "domain" {
  value = data.digitalocean_domain.default
}


# ============================== DO Relational Database ==========================

output "database_clusters" {
  value = {
    for idx, cluster in digitalocean_database_cluster.regional : var.regions[idx] => {
      id       = cluster.id
      host     = cluster.host
      port     = cluster.port
      user     = "doadmin"
      password = cluster.password
      region   = cluster.region
      name     = cluster.name
    }
  }
  sensitive = true
}

# output "database_cluster_id" {
#   value = digitalocean_database_cluster.hive-db.id
# }

# output "database_cluster_host" {
#   value = digitalocean_database_cluster.hive-db.host
# }

# output "database_cluster_user" {
#   value = "doadmin"
# }

# output "database_cluster_password" {
#   value     = digitalocean_database_cluster.hive-db.password
#   sensitive = true
# }

# output "database_cluster_port" {
#   value = digitalocean_database_cluster.hive-db.port
# }

# ============================== DO Space ==========================

# output "space_name" {
#   value = digitalocean_spaces_bucket.regional.name
# }

# output "space_region" {
#   value = digitalocean_spaces_bucket.regional.region
# }

output "spaces" {
  value = {
    for space in digitalocean_spaces_bucket.regional :
    space.name => {
      name   = space.name
      region = space.region
    }
  }
}

output "spaces_by_region" {
  value = {
    for idx, space in digitalocean_spaces_bucket.regional : var.regions[idx] => {
      name     = space.name
      region   = space.region
      endpoint = "https://${space.name}.${space.region}.digitaloceanspaces.com"
    }
  }
}

# VPC Outputs
output "vpcs" {
  value = {
    for vpc in digitalocean_vpc.regional :
    vpc.region => {
      id         = vpc.id
      name       = vpc.name
      ip_range   = vpc.ip_range
      region     = vpc.region
      created_at = vpc.created_at
    }
  }
}
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
  value = digitalocean_domain.default.name
} 
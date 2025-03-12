resource "digitalocean_project" "project" {
  name        = var.project_name
  description = "Hivenetes Global Load Balancer Project"
  purpose     = "Web Application"
  environment = "Production"
} 
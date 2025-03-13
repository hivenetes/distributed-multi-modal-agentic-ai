resource "digitalocean_project" "project" {
  name        = var.project_name
  description = "Distributed Multi-Modal AI Agents"
  purpose     = "Event-Driven Architecture"
  environment = "Development"
} 
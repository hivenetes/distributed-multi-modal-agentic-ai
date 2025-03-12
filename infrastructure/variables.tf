variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "DigitalOcean Project Name"
  type        = string
  default     = "devoxx-greece"
}

variable "domain" {
  description = "Domain for the load balancer"
  type        = string
  default     = "heartbyte.io"
}

variable "regions" {
  description = "Regions for deployment"
  type        = list(string)
  default     = ["ams3", "blr1", "nyc1"]
}

variable "droplet_size" {
  description = "Size of the droplets"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Image for the droplets"
  type        = string
  default     = "ubuntu-20-04-x64"
} 
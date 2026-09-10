variable "do_token" {
  type        = string
  description = "DigitalOcean API Personal Access Token"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g. prod, staging, dev)"
  default     = "prod"
}

variable "region" {
  type        = string
  description = "DigitalOcean datacenter region (e.g. nyc1, fra1, ams3, blr1)"
  default     = "nyc1"
}

variable "datacenter" {
  type        = string
  description = "Consul/Nomad datacenter identifier"
  default     = "dc1"
}

variable "vpc_ip_range" {
  type        = string
  description = "CIDR block for the DigitalOcean private VPC"
  default     = "10.136.0.0/16"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content for administrative cluster access"
}

variable "admin_allowed_cidrs" {
  type        = list(string)
  description = "List of public IPv4/IPv6 CIDRs authorized to connect to Bastion via SSH"
  default     = ["0.0.0.0/0"] # Recommendation: Restrict to corporate VPN or office IPs in production
}

variable "bastion_droplet_size" {
  type        = string
  description = "Droplet slug for the Bastion gateway"
  default     = "s-1vcpu-1gb"
}

variable "server_droplet_size" {
  type        = string
  description = "Droplet slug for Consul/Nomad management servers"
  default     = "s-2vcpu-4gb"
}

variable "server_count" {
  type        = number
  description = "Number of Consul/Nomad server nodes (recommended 3 or 5 for quorum)"
  default     = 3
}

variable "worker_droplet_size" {
  type        = string
  description = "Droplet slug for compute worker droplets"
  default     = "s-4vcpu-8gb"
}

variable "worker_count" {
  type        = number
  description = "Number of Nomad compute clients (for Kafka, Grafana, Extractors)"
  default     = 3
}

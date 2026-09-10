output "vpc_id" {
  description = "DigitalOcean VPC Network Identifier"
  value       = digitalocean_vpc.do_cluster_vpc.id
}

output "vpc_ip_range" {
  description = "DigitalOcean VPC CIDR range"
  value       = digitalocean_vpc.do_cluster_vpc.ip_range
}

output "bastion_public_ip" {
  description = "Public IPv4 address of the Bastion gateway host"
  value       = digitalocean_droplet.bastion.ipv4_address
}

output "bastion_private_ip" {
  description = "Private VPC IPv4 address of the Bastion gateway host"
  value       = digitalocean_droplet.bastion.ipv4_address_private
}

output "consul_nomad_servers_private_ips" {
  description = "Private VPC IPv4 addresses for Consul/Nomad management server droplets"
  value       = digitalocean_droplet.hashi_servers[*].ipv4_address_private
}

output "nomad_workers_private_ips" {
  description = "Private VPC IPv4 addresses for worker compute droplets (Kafka, Grafana, Extractors)"
  value       = digitalocean_droplet.workers[*].ipv4_address_private
}

output "bastion_ssh_command" {
  description = "SSH command to connect to Bastion gateway"
  value       = "ssh -i ~/.ssh/id_rsa root@${digitalocean_droplet.bastion.ipv4_address}"
}

output "bastion_proxyjump_example" {
  description = "Example SSH command jumping through Bastion to an internal cluster node"
  value       = "ssh -J root@${digitalocean_droplet.bastion.ipv4_address} root@<INTERNAL_PRIVATE_IP>"
}

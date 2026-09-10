terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
resource "digitalocean_vpc" "do_cluster_vpc" {
  name        = "${var.environment}-do-cluster-vpc"
  region      = var.region
  ip_range    = var.vpc_ip_range
  description = "Isolated VPC for Digital Ocean Production Cluster and Data Extraction Pipelines"
}

# -----------------------------------------------------------------------------
# SSH Key
# -----------------------------------------------------------------------------
resource "digitalocean_ssh_key" "cluster_admin_key" {
  name       = "${var.environment}-cluster-admin"
  public_key = var.ssh_public_key
}

# -----------------------------------------------------------------------------
# Bastion Host (Gateway into VPC)
# -----------------------------------------------------------------------------
resource "digitalocean_droplet" "bastion" {
  image      = "ubuntu-24-04-x64"
  name       = "${var.environment}-bastion"
  region     = var.region
  size       = var.bastion_droplet_size
  vpc_uuid   = digitalocean_vpc.do_cluster_vpc.id
  ssh_keys   = [digitalocean_ssh_key.cluster_admin_key.id]
  user_data  = file("${path.module}/cloud-init/bastion.yaml")

  tags = [
    var.environment,
    "bastion",
    "security-gateway"
  ]
}

# -----------------------------------------------------------------------------
# Consul & Nomad Server Droplets
# -----------------------------------------------------------------------------
resource "digitalocean_droplet" "hashi_servers" {
  count      = var.server_count
  image      = "ubuntu-24-04-x64"
  name       = "${var.environment}-hashi-server-0${count.index + 1}"
  region     = var.region
  size       = var.server_droplet_size
  vpc_uuid   = digitalocean_vpc.do_cluster_vpc.id
  ssh_keys   = [digitalocean_ssh_key.cluster_admin_key.id]
  user_data  = templatefile("${path.module}/cloud-init/consul_nomad_server.yaml", {
    SERVER_COUNT = var.server_count
    DATACENTER   = var.datacenter
    NODE_INDEX   = count.index + 1
  })

  tags = [
    var.environment,
    "consul-server",
    "nomad-server"
  ]
}

# -----------------------------------------------------------------------------
# Worker / Compute Droplets (Nomad Clients: Kafka, Grafana, Extractors)
# -----------------------------------------------------------------------------
resource "digitalocean_droplet" "workers" {
  count      = var.worker_count
  image      = "ubuntu-24-04-x64"
  name       = "${var.environment}-nomad-worker-0${count.index + 1}"
  region     = var.region
  size       = var.worker_droplet_size
  vpc_uuid   = digitalocean_vpc.do_cluster_vpc.id
  ssh_keys   = [digitalocean_ssh_key.cluster_admin_key.id]
  user_data  = templatefile("${path.module}/cloud-init/nomad_client.yaml", {
    DATACENTER = var.datacenter
    NODE_INDEX = count.index + 1
  })

  tags = [
    var.environment,
    "nomad-worker",
    "kafka",
    "grafana",
    "extractors"
  ]
}

# -----------------------------------------------------------------------------
# Cloud Firewalls
# -----------------------------------------------------------------------------

# 1. Bastion Firewall: Restrict SSH to authorized IPs only
resource "digitalocean_firewall" "bastion_firewall" {
  name        = "${var.environment}-bastion-fw"
  droplet_ids = [digitalocean_droplet.bastion.id]

  # Allow inbound SSH only from whitelisted administration CIDRs
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.admin_allowed_cidrs
  }

  # Allow all outbound traffic from bastion (package updates, etc.)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 2. Internal VPC Firewall: Strict ingress, no public exposure except via Bastion
resource "digitalocean_firewall" "internal_cluster_firewall" {
  name = "${var.environment}-internal-cluster-fw"
  droplet_ids = concat(
    digitalocean_droplet.hashi_servers[*].id,
    digitalocean_droplet.workers[*].id
  )

  # Inbound SSH strictly from the Bastion droplet
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "22"
    source_droplet_ids        = [digitalocean_droplet.bastion.id]
  }

  # Inbound Consul Gossip / RPC within VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8300-8600"
    source_addresses = [var.vpc_ip_range]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "8301-8302"
    source_addresses = [var.vpc_ip_range]
  }

  # Inbound Nomad RPC / HTTP / Serf within VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "4646-4648"
    source_addresses = [var.vpc_ip_range]
  }

  # Inbound Kafka broker & KRaft ports within VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9092-9094"
    source_addresses = [var.vpc_ip_range]
  }

  # Inbound Grafana web UI (reachable through Bastion SSH tunnel or internal VPC)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = [var.vpc_ip_range]
    source_droplet_ids = [digitalocean_droplet.bastion.id]
  }

  # Outbound: allow access to internet (for Microsoft, HubSpot, Salesforce API calls)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

job "consul-client" {
  datacenters = ["dc1"]
  type        = "system" # Runs on every Nomad worker client

  group "consul-agent" {
    network {
      port "dns" {
        static = 8600
      }
      port "http" {
        static = 8500
      }
      port "serf_lan" {
        static = 8301
      }
    }

    task "consul" {
      driver = "docker"

      config {
        image        = "hashicorp/consul:1.19.1"
        network_mode = "host"
        args = [
          "agent",
          "-bind={{ GetInterfaceIP \"eth1\" }}",
          "-client=0.0.0.0",
          "-retry-join=provider=digitalocean tag_name=consul-server",
          "-datacenter=dc1",
          "-data-dir=/consul/data"
        ]
      }

      resources {
        cpu    = 200 # MHz
        memory = 256 # MB
      }

      service {
        name = "consul-client"
        port = "http"
        tags = ["service-mesh", "dns"]

        check {
          name     = "consul-agent-health"
          type     = "http"
          path     = "/v1/status/leader"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

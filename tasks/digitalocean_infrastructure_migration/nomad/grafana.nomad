job "grafana" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "grafana" {
        static = 3000
        to     = 3000
      }
    }

    volume "grafana_storage" {
      type      = "host"
      read_only = false
      source    = "grafana_data"
    }

    task "grafana" {
      driver = "docker"

      volume_mount {
        volume      = "grafana_storage"
        destination = "/var/lib/grafana"
      }

      config {
        image = "grafana/grafana:11.1.0"
        ports = ["grafana"]
      }

      env {
        GF_SECURITY_ADMIN_USER     = "admin"
        GF_SECURITY_ADMIN_PASSWORD = "devops_do_secure_password"
        GF_USERS_ALLOW_SIGN_UP     = "false"
        GF_SERVER_SERVE_FROM_SUB_PATH = "false"
        GF_INSTALL_PLUGINS         = "grafana-piechart-panel,grafana-clock-panel"
      }

      resources {
        cpu    = 500  # MHz
        memory = 512  # MB
      }

      service {
        name = "grafana"
        port = "grafana"
        tags = ["observability", "ui", "monitoring"]

        check {
          name     = "grafana-health-check"
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }
  }
}

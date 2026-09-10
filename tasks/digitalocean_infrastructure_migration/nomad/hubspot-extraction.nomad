job "hubspot-extraction" {
  datacenters = ["dc1"]
  type        = "service"

  group "extractor" {
    count = 1

    restart {
      attempts = 5
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "1h"
      unlimited      = true
    }

    task "hubspot-worker" {
      driver = "docker"

      config {
        image = "registry.digitalocean.com/cluster-registry/hubspot-extractor:v1.0.0"
      }

      env {
        EXTRACTION_SOURCE        = "hubspot"
        KAFKA_BOOTSTRAP_SERVERS  = "kafka.service.consul:9092"
        KAFKA_TOPIC              = "extractions.hubspot"
        KAFKA_DLQ_TOPIC          = "extractions.dlq"
        POLL_INTERVAL_SECONDS    = "60"
        BATCH_SIZE               = "100"
        RATE_LIMIT_PER_SECOND    = "10"
        STATE_BACKEND            = "consul"
        CONSUL_HTTP_ADDR         = "http://127.0.0.1:8500"
        LOG_LEVEL                = "INFO"
      }

      template {
        data = <<EOH
HUBSPOT_ACCESS_TOKEN="{{ keyOrDefault "secret/extractions/hubspot/access_token" "mock-hubspot-token" }}"
EOH
        destination = "secrets/env"
        env         = true
      }

      resources {
        cpu    = 500 # MHz
        memory = 512 # MB
      }

      service {
        name = "hubspot-extraction"
        tags = ["etl", "extractor", "hubspot", "crm"]

        check {
          name     = "extractor-heartbeat-check"
          type     = "script"
          command  = "/bin/sh"
          args     = ["-c", "test -f /tmp/extractor_alive && test $(find /tmp/extractor_alive -mmin -2)"]
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}

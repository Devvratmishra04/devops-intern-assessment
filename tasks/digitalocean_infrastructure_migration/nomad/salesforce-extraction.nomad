job "salesforce-extraction" {
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

    task "salesforce-worker" {
      driver = "docker"

      config {
        image = "registry.digitalocean.com/cluster-registry/salesforce-extractor:v1.0.0"
      }

      env {
        EXTRACTION_SOURCE        = "salesforce"
        KAFKA_BOOTSTRAP_SERVERS  = "kafka.service.consul:9092"
        KAFKA_TOPIC              = "extractions.salesforce"
        KAFKA_DLQ_TOPIC          = "extractions.dlq"
        POLL_INTERVAL_SECONDS    = "60"
        BATCH_SIZE               = "200"
        STATE_BACKEND            = "consul"
        CONSUL_HTTP_ADDR         = "http://127.0.0.1:8500"
        LOG_LEVEL                = "INFO"
      }

      template {
        data = <<EOH
SF_CLIENT_ID="{{ keyOrDefault "secret/extractions/salesforce/client_id" "mock-sf-client-id" }}"
SF_CLIENT_SECRET="{{ keyOrDefault "secret/extractions/salesforce/client_secret" "mock-sf-client-secret" }}"
SF_USERNAME="{{ keyOrDefault "secret/extractions/salesforce/username" "devops@company.com" }}"
SF_PASSWORD="{{ keyOrDefault "secret/extractions/salesforce/password" "mock-sf-pass" }}"
SF_SECURITY_TOKEN="{{ keyOrDefault "secret/extractions/salesforce/security_token" "mock-sf-token" }}"
SF_INSTANCE_URL="{{ keyOrDefault "secret/extractions/salesforce/instance_url" "https://login.salesforce.com" }}"
EOH
        destination = "secrets/env"
        env         = true
      }

      resources {
        cpu    = 500 # MHz
        memory = 512 # MB
      }

      service {
        name = "salesforce-extraction"
        tags = ["etl", "extractor", "salesforce", "crm"]

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

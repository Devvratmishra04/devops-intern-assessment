job "kafka" {
  datacenters = ["dc1"]
  type        = "service"

  group "broker" {
    count = 1

    network {
      port "kafka" {
        static = 9092
        to     = 9092
      }
      port "kraft" {
        static = 9093
        to     = 9093
      }
      port "exporter" {
        static = 9308
        to     = 9308
      }
    }

    volume "kafka_data" {
      type      = "host"
      read_only = false
      source    = "kafka_storage"
    }

    task "kafka-broker" {
      driver = "docker"

      volume_mount {
        volume      = "kafka_data"
        destination = "/bitnami/kafka"
      }

      config {
        image = "bitnami/kafka:3.7.0"
        ports = ["kafka", "kraft"]
      }

      env {
        KAFKA_ENABLE_KRAFT                 = "yes"
        KAFKA_CFG_NODE_ID                  = "1"
        KAFKA_CFG_PROCESS_ROLES            = "broker,controller"
        KAFKA_CFG_CONTROLLER_LISTENER_NAMES = "CONTROLLER"
        KAFKA_CFG_LISTENERS                = "PLAINTEXT://:9092,CONTROLLER://:9093"
        KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
        KAFKA_CFG_ADVERTISED_LISTENERS     = "PLAINTEXT://kafka.service.consul:9092"
        KAFKA_CFG_CONTROLLER_QUORUM_VOTERS = "1@127.0.0.1:9093"
        ALLOW_PLAINTEXT_LISTENER           = "yes"
        KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE = "true"
        KAFKA_CFG_DEFAULT_REPLICATION_FACTOR = "1"
        KAFKA_CFG_NUM_PARTITIONS           = "3"
        KAFKA_CFG_LOG_RETENTION_HOURS      = "168" # 7 days
      }

      resources {
        cpu    = 2000 # 2 GHz
        memory = 2048 # 2 GB
      }

      service {
        name = "kafka"
        port = "kafka"
        tags = ["event-bus", "streaming", "messaging"]

        check {
          name     = "kafka-tcp-check"
          type     = "tcp"
          interval = "10s"
          timeout  = "3s"
        }
      }
    }

    task "kafka-topic-init" {
      driver = "docker"
      lifecycle {
        hook    = "poststart"
        sidecar = false
      }

      config {
        image   = "bitnami/kafka:3.7.0"
        command = "bash"
        args = [
          "-c",
          "sleep 8 && kafka-topics.sh --bootstrap-server kafka.service.consul:9092 --create --if-not-exists --topic extractions.microsoft --partitions 3 --replication-factor 1 && kafka-topics.sh --bootstrap-server kafka.service.consul:9092 --create --if-not-exists --topic extractions.hubspot --partitions 3 --replication-factor 1 && kafka-topics.sh --bootstrap-server kafka.service.consul:9092 --create --if-not-exists --topic extractions.salesforce --partitions 3 --replication-factor 1 && kafka-topics.sh --bootstrap-server kafka.service.consul:9092 --create --if-not-exists --topic extractions.dlq --partitions 3 --replication-factor 1 && echo 'All extraction topics provisioned successfully!'"
        ]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }

    task "kafka-exporter" {
      driver = "docker"

      config {
        image = "danielqsj/kafka-exporter:v1.7.0"
        args  = ["--kafka.server=127.0.0.1:9092"]
        ports = ["exporter"]
      }

      resources {
        cpu    = 150
        memory = 128
      }

      service {
        name = "kafka-exporter"
        port = "exporter"
        tags = ["prometheus", "metrics"]

        check {
          name     = "http-metrics-check"
          type     = "http"
          path     = "/metrics"
          interval = "15s"
          timeout  = "3s"
        }
      }
    }
  }
}

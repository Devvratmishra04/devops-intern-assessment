job "hello-devops" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 1

    task "hello" {
      driver = "docker"

      config {
        image = "hello-devops:latest"
      }

      resources {
        cpu    = 100  # MHz
        memory = 128  # MB
      }

      logs {
        max_files     = 3
        max_file_size = 10  # MB
      }
    }
  }
}

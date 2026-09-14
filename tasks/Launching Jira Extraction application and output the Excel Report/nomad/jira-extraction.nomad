# ── Jira Extraction – Nomad Periodic Batch Job ────────────────
# Runs daily at 06:00 UTC to extract Jira issues and produce
# Excel reports.  Secrets injected from Consul KV / Vault.
#
# Deploy:
#   nomad job run nomad/jira-extraction.nomad
#
# Check status:
#   nomad job status jira-extraction
#   nomad job periodic force jira-extraction   # trigger immediately
# ──────────────────────────────────────────────────────────────

job "jira-extraction" {
  datacenters = ["dc1"]
  type        = "batch"

  # ── Periodic scheduling ────────────────────────────────────
  periodic {
    cron             = "0 6 * * *"      # Every day at 06:00 UTC
    prohibit_overlap = true
    time_zone        = "UTC"
  }

  # ── Extraction group ───────────────────────────────────────
  group "extractor" {
    count = 1

    restart {
      attempts = 3
      interval = "10m"
      delay    = "30s"
      mode     = "fail"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "1h"
      unlimited      = false
      attempts       = 5
    }

    # Host volume for persisting generated Excel reports
    volume "reports" {
      type      = "host"
      source    = "jira-reports"
      read_only = false
    }

    # ── Worker task ──────────────────────────────────────────
    task "jira-worker" {
      driver = "docker"

      config {
        image = "registry.digitalocean.com/cluster-registry/jira-extraction:v1.0.0"

        volumes = [
          "local/config.json:/app/config.json",
        ]
      }

      volume_mount {
        volume      = "reports"
        destination = "/app/output"
        read_only   = false
      }

      # Static environment variables
      env {
        PYTHONUNBUFFERED = "1"
        LOG_LEVEL        = "INFO"
      }

      # Secrets injected from Consul KV (or Vault)
      template {
        data = <<EOH
JIRA_URL="{{ keyOrDefault "secret/jira/url" "https://glynac.atlassian.net" }}"
JIRA_EMAIL="{{ keyOrDefault "secret/jira/email" "dvp@glynac.ai" }}"
JIRA_API_TOKEN="{{ keyOrDefault "secret/jira/api_token" "" }}"
EOH
        destination = "secrets/env"
        env         = true
      }

      # Embed the application config as a template
      template {
        data = <<EOF
{
    "default_jql": "project IS NOT EMPTY ORDER BY created DESC",
    "max_results_per_page": 100,
    "output_directory": "output",
    "fields": [
        "key", "summary", "status", "priority", "issuetype",
        "assignee", "reporter", "created", "updated",
        "resolutiondate", "resolution", "labels", "components",
        "fixVersions", "sprint", "timeoriginalestimate",
        "timeestimate", "timespent", "description"
    ],
    "report_templates": {
        "all_issues": "project IS NOT EMPTY ORDER BY created DESC",
        "open_bugs": "issuetype = Bug AND resolution = Unresolved ORDER BY priority DESC",
        "recent_30_days": "created >= -30d ORDER BY created DESC",
        "my_open_issues": "assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC",
        "sprint_active": "sprint in openSprints() ORDER BY rank ASC"
    }
}
EOF
        destination = "local/config.json"
      }

      resources {
        cpu    = 500   # MHz
        memory = 512   # MB
      }

      service {
        name = "jira-extraction"
        tags = ["etl", "extractor", "jira", "batch"]

        check {
          type     = "script"
          command  = "python"
          args     = ["jira_extraction.py", "--help"]
          interval = "30s"
          timeout  = "10s"
        }
      }

      logs {
        max_files     = 5
        max_file_size = 10
      }
    }
  }
}

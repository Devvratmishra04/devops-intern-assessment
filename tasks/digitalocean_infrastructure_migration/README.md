# Digital Ocean Infrastructure Migration & Services Deployment

This task directory contains the complete infrastructure-as-code, orchestration definitions, containerized extraction pipelines, and automated migration runner for establishing a new **Digital Ocean** production setup.

---

## Acceptance Criteria Coverage

| Required Component | Implementation Location | Description |
|---|---|---|
| **Bastion** | `terraform/main.tf`, `terraform/cloud-init/bastion.yaml` | Hardened jump host with UFW, fail2ban, and restricted SSH ingress |
| **Kafka** | `nomad/kafka.nomad` | Apache Kafka in KRaft mode with 4 auto-provisioned extraction topics |
| **Grafana** | `nomad/grafana.nomad`, `monitoring/` | Monitoring hub with Prometheus datasources and 2 pre-configured dashboards |
| **Consul** | `terraform/cloud-init/consul_nomad_server.yaml`, `nomad/consul.nomad` | 3-node HA service mesh, internal DNS, and dynamic service registration |
| **Nomad** | `terraform/cloud-init/nomad_client.yaml`, `nomad/` | Workload cluster orchestrating Kafka, Grafana, and extraction workers |
| **Microsoft extraction** | `extractions/microsoft/`, `nomad/microsoft-extraction.nomad` | Microsoft Graph API delta extractor publishing to `extractions.microsoft` |
| **Hubspot extraction** | `extractions/hubspot/`, `nomad/hubspot-extraction.nomad` | HubSpot CRM API rate-throttled extractor publishing to `extractions.hubspot` |
| **Salesforce extraction**| `extractions/salesforce/`, `nomad/salesforce-extraction.nomad`| Salesforce SOQL cursor-based extractor publishing to `extractions.salesforce` |

---

## Directory Structure

```
tasks/digitalocean_infrastructure_migration/
├── terraform/                       # DigitalOcean Infrastructure as Code
│   ├── main.tf                      # Droplets, VPC, Firewalls, SSH keys
│   ├── variables.tf                 # Configurable deployment parameters
│   ├── outputs.tf                   # Exported IPs and SSH commands
│   ├── terraform.tfvars.example     # Sample configuration values
│   └── cloud-init/                  # Automated node bootstrap scripts
│       ├── bastion.yaml             # Bastion hardening & fail2ban
│       ├── consul_nomad_server.yaml # Consul & Nomad server cluster setup
│       └── nomad_client.yaml        # Worker node Docker & Nomad client setup
├── nomad/                           # HashiCorp Nomad Job Definitions
│   ├── consul.nomad                 # Consul system-agent across nodes
│   ├── kafka.nomad                  # Apache Kafka KRaft broker & topics
│   ├── grafana.nomad                # Grafana observability service
│   ├── microsoft-extraction.nomad   # Microsoft Graph API extraction job
│   ├── hubspot-extraction.nomad     # HubSpot CRM extraction job
│   └── salesforce-extraction.nomad  # Salesforce CRM extraction job
├── extractions/                     # Containerized Ingestion Microservices
│   ├── common/                      # Shared Kafka producer & state store
│   │   ├── config.py
│   │   ├── kafka_producer.py
│   │   └── state_store.py
│   ├── microsoft/                   # Microsoft Graph extractor & Dockerfile
│   ├── hubspot/                     # HubSpot CRM extractor & Dockerfile
│   └── salesforce/                  # Salesforce SOQL extractor & Dockerfile
├── monitoring/                      # Observability Artifacts
│   ├── dashboards/                  # Pre-configured Grafana JSON dashboards
│   │   ├── digitalocean_cluster_overview.json
│   │   └── extractions_telemetry_dashboard.json
│   └── datasources/                 # Grafana datasource provisioning
├── migration/                       # Automated Migration & Test Engine
│   ├── migration_runner.py          # 7-stage end-to-end migration orchestrator
│   └── verify_migration.py          # Acceptance criteria verification test suite
├── .env.example                     # Environment variables template
├── DIGITALOCEAN_MIGRATION_ARCHITECTURE.md # Full architectural deep-dive manual
├── DigitalOcean_Setup_and_Migration_Guide.docx # Word guide
├── generate_docx.py                 # Script to regenerate Word document
└── README.md                        # This runbook
```

---

## Quick Start & Verification

### 1. Run the Migration Orchestrator (Dry Run / Smoke Test)
```bash
py tasks/digitalocean_infrastructure_migration/migration/migration_runner.py --dry-run
```

### 2. Run the Acceptance Criteria Verification Suite
```bash
py tasks/digitalocean_infrastructure_migration/migration/verify_migration.py
```

### 3. Generate the Executive Word Guide
```bash
py tasks/digitalocean_infrastructure_migration/generate_docx.py
```

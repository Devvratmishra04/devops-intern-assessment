# Research: Prometheus Metrics Exposed by HashiCorp Nomad, Consul, and Vault

## Overview
This task folder contains detailed technical research on how HashiCorp **Nomad**, **Consul**, and **Vault** expose Prometheus metrics, how to configure telemetry for each service, standard endpoint paths, and key metrics for monitoring cluster health, performance, and security.

---

## Quick Navigation
- 📖 [PROMETHEUS_METRICS_GUIDE.md](file:///c:/Internships/devops/tasks/hashicorp_prometheus_metrics/PROMETHEUS_METRICS_GUIDE.md) — Comprehensive metric dictionary, descriptions, and Prometheus alert rules.
- ⚙️ [prometheus_scrape_config.yml](file:///c:/Internships/devops/tasks/hashicorp_prometheus_metrics/prometheus_scrape_config.yml) — Ready-to-use Prometheus scrape job definitions.

---

## Endpoint & Telemetry Summary Table

| Service | Telemetry Config snippet | Default Endpoint | Default Auth Requirement |
| :--- | :--- | :--- | :--- |
| **Nomad** | `telemetry { prometheus_metrics = true }` | `GET /v1/metrics?format=prometheus` | Port `4646` (None if HTTP unauthenticated, or ACL Token) |
| **Consul** | `telemetry { prometheus_retention_time = "24h", disable_hostname = true }` | `GET /v1/agent/metrics?format=prometheus` | Port `8500` (Requires `agent:read` ACL token if ACLs enabled) |
| **Vault** | `telemetry { prometheus_retention_time = "24h", disable_hostname = true }` | `GET /v1/sys/metrics?format=prometheus` | Port `8200` (Token required UNLESS `unauthenticated_metrics_access = true`) |

---

## Core Scrape Architecture

```
                    ┌─────────────────────────┐
                    │    Prometheus Server    │
                    └────────────┬────────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │ Scrape /v1/metrics  │ Scrape              │ Scrape /v1/sys/metrics
           │ ?format=prometheus  │ /v1/agent/metrics   │ ?format=prometheus
           ▼                     ▼                     ▼
    ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
    │ Nomad Agent │       │ Consul Agent│       │ Vault Server│
    │ (Port 4646) │       │ (Port 8500) │       │ (Port 8200) │
    └─────────────┘       └─────────────┘       └─────────────┘
```

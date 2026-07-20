# Vault Cluster Health Grafana Dashboard

## Overview
This task folder contains a production-ready Grafana dashboard JSON model for monitoring **HashiCorp Vault Cluster Health** via Prometheus metrics.

---

## Included Files
- 📊 **[vault_cluster_health_dashboard.json](file:///c:/Internships/devops/tasks/vault_grafana_dashboard/vault_cluster_health_dashboard.json)** — Grafana Dashboard JSON definition ready to import into Grafana (Dashboard UID: `vault-cluster-health`).

---

## Dashboard Section Breakdown

### 1. Vault Core & HA Status
- **Seal Status**: Whether the Vault instance is sealed or unsealed (`vault_core_unsealed`). Green = Unsealed, Red = SEALED.
- **Active Node**: Whether this node is the active leader (`vault_core_active`). Green = Active Leader, Yellow = Standby.
- **HA Enabled**: Whether high-availability mode is enabled (`vault_core_ha_enabled`). Green = Enabled, Red = Disabled.
- **Standby Nodes**: Count of nodes currently in standby (`count(vault_core_active == 0)`).

### 2. Token & Lease Management
- **Token Creation Rate**: Rate of new token creation over 5 minutes (`rate(vault_token_creation[5m])`).
- **Active Leases**: Current number of active secret leases (`vault_expire_num_leases`). Thresholds at 10k (yellow) and 50k (red).
- **Lease Creation Rate**: Rate of new lease creation (`rate(vault_secret_lease_creation[5m])`).
- **Token Count by TTL**: Bar gauge breakdown of active tokens grouped by TTL bucket (`vault_token_count_by_ttl`).

### 3. Storage Backend Performance
- **Barrier GET Latency**: Time for barrier storage GET operations in ms (`vault_barrier_get`).
- **Barrier PUT Latency**: Time for barrier storage PUT operations in ms (`vault_barrier_put`).
- **Barrier DELETE Latency**: Time for barrier storage DELETE operations in ms (`vault_barrier_delete`).
- All three panels share yellow (50 ms) and red (200 ms) latency thresholds.

### 4. Audit & Security
- **Audit Log Request Count**: Rate of audit log requests over 5 minutes (`rate(vault_audit_log_request_count[5m])`).
- **Audit Log Failures**: Count of failed audit log writes (`vault_audit_log_request_failure`). Displays "OK" in green when 0, "CRITICAL" in red when > 0.
- **Policy GET Count**: Rate of policy read operations (`rate(vault_policy_get_policy[5m])`).

---

## Dashboard Properties
| Property        | Value                                                |
|-----------------|------------------------------------------------------|
| **UID**         | `vault-cluster-health`                               |
| **Refresh**     | 10 seconds                                           |
| **Time Range**  | Last 1 hour                                          |
| **Style**       | Dark                                                 |
| **Datasource**  | Prometheus (uid: `prometheus`)                       |
| **Tags**        | `vault`, `cluster-health`, `hashicorp`, `prometheus` |

---

## How to Import into Grafana

1. Open Grafana UI (e.g. `http://localhost:3000`).
2. Navigate to **Dashboards** > **Import**.
3. Click **Upload JSON file** and select `vault_cluster_health_dashboard.json` (or paste the JSON content).
4. Select your **Prometheus** data source and click **Import**.

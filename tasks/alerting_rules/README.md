# Alerting Rules for Critical Metrics

## Overview
This task sets up a complete, production-grade Prometheus + Alertmanager alerting pipeline for the HashiCorp infrastructure (Nomad, Consul, Vault) plus Prometheus self-monitoring.

---

## Files

| File | Location | Purpose |
|:--|:--|:--|
| [prometheus_alert_rules.yml](file:///c:/Internships/devops/monitoring/prometheus_alert_rules.yml) | `monitoring/` | 30+ Prometheus alert rules across 5 groups |
| [prometheus_recording_rules.yml](file:///c:/Internships/devops/monitoring/prometheus_recording_rules.yml) | `monitoring/` | Pre-computed recording rules for dashboard performance |
| [alertmanager.yml](file:///c:/Internships/devops/monitoring/alertmanager.yml) | `monitoring/` | Alertmanager routing, receivers, and notification config |
| [prometheus.yml](file:///c:/Internships/devops/monitoring/prometheus.yml) | `monitoring/` | Prometheus scrape config (updated with all rule files) |
| [ALERTING_RUNBOOK.md](file:///c:/Internships/devops/tasks/alerting_rules/ALERTING_RUNBOOK.md) | `tasks/alerting_rules/` | On-call runbook with remediation steps per alert |

---

## Alert Severity Tiers

| Severity | Routing | Response SLA | Examples |
|:--|:--|:--|:--|
| **`critical`** | PagerDuty + Slack `#alerts-critical` + Email | **Immediate** (< 5 min) | VaultSealed, NoLeader, AuditLogFailure |
| **`warning`** | Slack `#alerts-warning` | **Within 30 min** | High latency, resource >85%, RPC errors |
| **`info`** | Slack `#alerts-info` | **Next business day** | Scrape target down, low headroom |

---

## Alert Coverage Matrix

| Service | Critical Alerts | Warning Alerts | Total |
|:--|:--|:--|:--|
| **Nomad** | 1 (NoLeader) | 6 (Memberlist, Raft, Job, CPU, Memory, Deployment) | 7 |
| **Consul** | 2 (NoLeader, NodeFailed) | 3 (LeaderContact, ServiceCritical, RPC) | 5 |
| **Vault** | 3 (Sealed, NoActive, AuditFailure) | 3 (BarrierGet, BarrierPut, HighLeases) | 6 |
| **Infrastructure** | 2 (TargetDown, PrometheusConfigReload) | 4 (ScrapeErrors, RuleEvalSlow, StorageFull, TSDBReload) | 6 |
| **Node/Host** | 2 (DiskFull, OOMKill) | 4 (HighCPU, HighMemory, DiskWarning, ClockSkew) | 6 |
| **Total** | **10** | **20** | **30** |

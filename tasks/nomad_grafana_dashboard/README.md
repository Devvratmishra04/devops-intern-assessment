# Nomad Cluster Health Grafana Dashboard

## Overview
This task folder contains a production-ready Grafana dashboard JSON model for monitoring **HashiCorp Nomad Cluster Health**.

---

## Included Files
- 📊 **[nomad_cluster_health_dashboard.json](file:///c:/Internships/devops/tasks/nomad_grafana_dashboard/nomad_cluster_health_dashboard.json)** — Grafana Dashboard JSON definition ready to import into Grafana (Dashboard ID: `nomad-cluster-health`).

---

## Dashboard Section Breakdown

### 1. Server & Client Node Status
- **Nomad Raft Leader Status**: Tracks active leader state (`nomad_nomad_raft_state == 1`).
- **Memberlist Cluster Health Score**: Monitors node network health (`nomad_nomad_memberlist_health_score`).
- **Raft Leader Contact Latency**: Contact latency in ms (`nomad_nomad_raft_leader_last_contact`).
- **Client Node Count & Status**: Number of active and registered clients.

### 2. Job Allocations & Failures
- **Job Status Breakdown**: Gauges for `running`, `pending`, and `dead` jobs (`nomad_nomad_job_status`).
- **Allocation State**: Active running vs failed allocations (`nomad_client_allocations_running`, `nomad_client_allocations_failed`).
- **Evaluation Status**: Counters for evaluation outcomes (`nomad_nomad_evaluations` - `complete`, `failed`, `blocked`).

### 3. Resource Utilization (CPU & Memory)
- **Cluster Allocated vs Unallocated CPU**: Total CPU MHz allocated across clients (`nomad_client_allocated_cpu` vs `nomad_client_unallocated_cpu`).
- **Cluster Allocated vs Unallocated Memory**: Total RAM bytes allocated across clients (`nomad_client_allocated_memory` vs `nomad_client_unallocated_memory`).
- **Top Allocation CPU Utilization**: `%` CPU consumption per task allocation (`nomad_client_allocs_cpu_total_percent`).
- **Top Allocation Memory Consumption**: RAM usage in bytes per allocation (`nomad_client_allocs_memory_usage`).

### 4. Deployment Status
- **Active Deployments**: Current live deployments (`nomad_nomad_deployments_active`).
- **Deployment Status Counters**: Total count of `successful`, `failed`, and `cancelled` deployments (`nomad_nomad_deployments_successful`, `nomad_nomad_deployments_failed`, `nomad_nomad_deployments_cancelled`).

---

## How to Import into Grafana

1. Open Grafana UI (e.g. `http://localhost:3000`).
2. Navigate to **Dashboards** > **Import**.
3. Click **Upload JSON file** and select `nomad_cluster_health_dashboard.json` (or paste the JSON content).
4. Select your **Prometheus** data source and click **Import**.

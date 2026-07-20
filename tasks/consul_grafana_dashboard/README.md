# Consul Cluster Health Grafana Dashboard

## Overview
This task folder contains a production-ready Grafana dashboard JSON model for monitoring **HashiCorp Consul Cluster Health**.

---

## Included Files
- 📊 **[consul_cluster_health_dashboard.json](file:///c:/Internships/devops/tasks/consul_grafana_dashboard/consul_cluster_health_dashboard.json)** — Grafana Dashboard JSON definition ready to import into Grafana (Dashboard UID: `consul-cluster-health`).

---

## Dashboard Section Breakdown

### 1. Cluster Health & Consensus
- **Raft Leader Status**: Tracks active leader state (`consul_raft_state == 1`). Green = Leader, Red = No Leader.
- **Leader Last Contact**: Contact latency in ms (`consul_raft_leader_lastContact`). Yellow >200ms, Red >500ms.
- **Serf Member Status**: Timeseries of Serf gossip membership status per node (`consul_serf_member_status`).
- **Server Node Count**: Total Raft-participating server nodes (`count(consul_raft_state)`).

### 2. Service Discovery & Health Checks
- **Service Health Status**: Timeseries of health check statuses by service and status label (`consul_health_service_status`).
- **Total Registered Services**: Count of services registered in the catalog (`consul_catalog_services`).
- **Nodes Per Service**: Bar gauge showing node count per service (`consul_catalog_service_nodes`).
- **Critical Checks Count**: Count of critical health checks (`consul_health_service_status{status="critical"}`). Red if >0.

### 3. Network & RPC Performance
- **RPC Request Rate**: Per-second rate of RPC requests (`rate(consul_rpc_request[5m])`).
- **RPC Request Errors**: Per-second rate of RPC errors (`rate(consul_rpc_request_error[5m])`).
- **DNS Query Time**: Domain query resolution time in ms (`consul_dns_domain_query_time_ms`).

### 4. Connect / Service Mesh
- **Connect CA Root Fetch Time**: Certificate Authority root fetch latency in ms (`consul_connect_ca_roots_get_ms`).

---

## How to Import into Grafana

1. Open Grafana UI (e.g. `http://localhost:3000`).
2. Navigate to **Dashboards** > **Import**.
3. Click **Upload JSON file** and select `consul_cluster_health_dashboard.json` (or paste the JSON content).
4. Select your **Prometheus** data source and click **Import**.

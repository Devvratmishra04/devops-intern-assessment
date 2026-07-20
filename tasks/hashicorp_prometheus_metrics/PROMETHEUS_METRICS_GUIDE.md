# Deep-Dive: Prometheus Metrics in Nomad, Consul & Vault

---

## 1. HashiCorp Nomad Metrics

Nomad agents (Servers and Clients) emit telemetry metrics formatted for Prometheus at `/v1/metrics?format=prometheus`.

### Telemetry Configuration (`nomad.hcl`)
```hcl
telemetry {
  collection_interval = "10s"
  disable_hostname    = true
  prometheus_metrics  = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}
```

### Essential Nomad Prometheus Metrics

#### A. Nomad Server & Cluster Health
- `nomad_nomad_memberlist_health_score`: Memberlist health score (0 = healthy, higher values indicate node network instability).
- `nomad_nomad_raft_state`: Current Raft node state (`1` = Leader, `2` = Follower, `3` = Candidate).
- `nomad_nomad_raft_leader_last_contact`: Time in milliseconds since last contact from Raft leader (should remain under heartbeat interval ~200ms).
- `nomad_nomad_raft_commit_index`: Highest log index committed by Raft consensus.

#### B. Nomad Job & Evaluation Metrics
- `nomad_nomad_job_status`: Gauge metric grouped by job ID and status (`running`, `pending`, `dead`).
- `nomad_nomad_evaluations`: Counter for Nomad job evaluation statuses (`pending`, `complete`, `failed`).
- `nomad_nomad_plan_queue_depth`: Number of pending evaluation plans queued for scheduling.

#### C. Nomad Client & Allocation Metrics
- `nomad_client_allocs_cpu_total_percent`: Percentage of host CPU utilized by a specific allocation (`alloc_id`, `job`, `task`).
- `nomad_client_allocs_memory_usage`: Memory consumption in bytes per allocation.
- `nomad_client_allocs_memory_max_usage`: Maximum peak memory consumed by allocation.
- `nomad_client_allocated_cpu`: Total CPU MHz allocated across node.
- `nomad_client_allocated_memory`: Total RAM bytes allocated across node.
- `nomad_client_unallocated_cpu`: Remaining unallocated CPU resources.
- `nomad_client_unallocated_memory`: Remaining unallocated memory capacity.

---

## 2. HashiCorp Consul Metrics

Consul agents expose Prometheus metrics at `/v1/agent/metrics?format=prometheus`.

### Telemetry Configuration (`consul.hcl`)
```hcl
telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}
```

### Essential Consul Prometheus Metrics

#### A. Cluster Health & Consensus
- `consul_raft_state`: Raft state (`1` = Leader, `2` = Follower).
- `consul_raft_leader_lastContact`: Milliseconds since last contact with Raft leader (>200ms alerts network partition/lag).
- `consul_serf_member_status`: Serf membership status for node (`1` = Alive, `2` = Leaving, `3` = Left, `4` = Failed).
- `consul_serf_queue_event_buffer_overflows`: Counter of dropped events due to buffer saturation.

#### B. Health Checks & Service Discovery
- `consul_health_service_status`: Gauge of registered service check statuses (`status="passing"`, `status="warning"`, `status="critical"`).
- `consul_health_node_status`: Node-level health check status gauge.
- `consul_catalog_services`: Total count of active registered service names in Consul Catalog.
- `consul_catalog_service_nodes`: Count of registered nodes per service.

#### C. Service Mesh (Consul Connect) & RPC
- `consul_dns_ptr_query_time_ms`: Summary of DNS resolve durations.
- `consul_rpc_request_error`: Counter of client-to-server RPC failures.
- `consul_connect_ca_roots_get_ms`: Time to retrieve certificate authority roots for Envoy sidecars.

---

## 3. HashiCorp Vault Metrics

Vault exposes metrics via `/v1/sys/metrics?format=prometheus`.

### Telemetry Configuration (`vault.hcl`)
```hcl
telemetry {
  prometheus_retention_time    = "24h"
  disable_hostname             = true
  unauthenticated_metrics_access = true  # Enables unauthenticated Prometheus scraping
}
```

### Essential Vault Prometheus Metrics

#### A. Vault Core & High Availability (HA) Status
- `vault_core_unsealed`: `1` if Vault node is unsealed, `0` if sealed (*Critical alert if 0*).
- `vault_core_active`: `1` if node is the active HA Leader, `0` if standby node.
- `vault_core_post_unseal_active`: `1` if active and fully initialized post-unseal.

#### B. Tokens, Leases, and Secret Engines
- `vault_token_creation`: Rate/counter of issued authentication tokens.
- `vault_token_count_by_ttl`: Histogram/gauge of tokens broken down by remaining TTL.
- `vault_secret_lease_creation`: Number of secret leases generated (e.g. database credentials, AWS IAM dynamic credentials).
- `vault_expire_num_leases`: Current active count of managed dynamic leases.

#### C. Storage Backend & Barrier Performance
- `vault_barrier_get`: Latency of storage reads through Vault's encrypted barrier.
- `vault_barrier_put`: Latency of storage writes through encrypted barrier.
- `vault_audit_log_request_count`: Rate of audit logs written (*If audit logging fails, Vault blocks all requests*).
- `vault_audit_log_request_failure`: Count of audit log write errors (*Critical alert*).

---

## 4. Key Prometheus Alert Rule Examples

```yaml
groups:
  - name: hashicorp_alerts
    rules:
      # Nomad Alerts
      - alert: NomadClusterNoLeader
        expr: count(nomad_nomad_raft_state == 1) == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Nomad cluster has no active Raft leader"

      # Consul Alerts
      - alert: ConsulServiceCritical
        expr: consul_health_service_status{status="critical"} > 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Consul health check failed for service {{ $labels.service_name }}"

      # Vault Alerts
      - alert: VaultSealed
        expr: vault_core_unsealed == 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Vault instance {{ $labels.instance }} is currently SEALED"
```

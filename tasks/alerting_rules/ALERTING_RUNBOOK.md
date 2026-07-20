# On-Call Alerting Runbook

This runbook provides step-by-step remediation procedures for every critical Prometheus alert in the HashiCorp monitoring stack. Each section is linked from the alert's `runbook_url` annotation.

---

## Nomad Alerts

### NomadNoLeader

**Severity**: 🔴 Critical
**Fires when**: No Nomad server reports Raft state `1` (Leader) for > 1 minute.

**Impact**: The cluster cannot schedule, evaluate, or manage any jobs. All Nomad API write operations will fail.

**Triage Steps**:
1. Check how many server nodes are running:
   ```bash
   nomad server members
   ```
2. If all servers are running but no leader, check Raft peer list:
   ```bash
   nomad operator raft list-peers
   ```
3. Check Nomad server logs for Raft election errors:
   ```bash
   journalctl -u nomad -f --grep "raft"
   ```
4. Verify network connectivity between server nodes (ports `4647`/`4648`).
5. If a single server is partitioned, restart the Nomad service on that node:
   ```bash
   systemctl restart nomad
   ```
6. **Last resort** — If quorum is permanently lost (majority of servers dead), perform Raft recovery:
   ```bash
   nomad operator raft remove-peer -address=<dead_node_address>
   ```

**Prevention**: Run an odd number of servers (3 or 5). Monitor `nomad_nomad_memberlist_health_score` for early warnings.

---

### NomadHighMemberlistHealthScore

**Severity**: 🟡 Warning
**Fires when**: `nomad_nomad_memberlist_health_score` > 3 for > 2 minutes.

**Impact**: Gossip protocol degradation. Nodes may not learn about new jobs, allocations, or peer state changes in a timely manner.

**Triage Steps**:
1. Check which nodes have elevated scores:
   ```bash
   nomad node status
   ```
2. Verify network latency between nodes:
   ```bash
   ping <peer_node_ip>
   ```
3. Check for packet loss or firewall rules blocking UDP port `4648` (Serf gossip).
4. Review system resource usage on affected nodes (CPU, memory, disk I/O).
5. If a single node is consistently unhealthy, drain and restart:
   ```bash
   nomad node drain -enable <node_id>
   systemctl restart nomad
   nomad node drain -disable <node_id>
   ```

---

## Consul Alerts

### ConsulNoLeader

**Severity**: 🔴 Critical
**Fires when**: No Consul server reports Raft state `1` (Leader) for > 1 minute.

**Impact**: Service discovery, health checks, KV store, and Connect/service mesh will all fail. Dependent services (Nomad, Vault) may also be affected.

**Triage Steps**:
1. Check Consul server member status:
   ```bash
   consul members -status=alive
   ```
2. List Raft peers:
   ```bash
   consul operator raft list-peers
   ```
3. Check Consul server logs:
   ```bash
   journalctl -u consul -f --grep "raft\|leader"
   ```
4. Verify connectivity on ports `8300` (server RPC), `8301` (Serf LAN), `8302` (Serf WAN).
5. If a server is stuck, restart the Consul agent:
   ```bash
   systemctl restart consul
   ```
6. **Last resort** — Raft peer removal if quorum is permanently lost:
   ```bash
   consul operator raft remove-peer -address=<dead_node_address>
   ```

**Prevention**: Always run 3 or 5 Consul servers. Monitor `consul_raft_leader_lastContact` for early detection.

---

### ConsulNodeFailed

**Severity**: 🔴 Critical
**Fires when**: `consul_serf_member_status == 4` (Failed) for > 1 minute.

**Impact**: The failed node's services are removed from the catalog. If it was a server node, quorum may be at risk.

**Triage Steps**:
1. Identify the failed node:
   ```bash
   consul members -status=failed
   ```
2. Check if the node is reachable via network:
   ```bash
   ping <node_ip>
   ssh <node_ip> "systemctl status consul"
   ```
3. If the node is down, restart the Consul agent:
   ```bash
   ssh <node_ip> "systemctl restart consul"
   ```
4. If the node is permanently decommissioned, force-leave:
   ```bash
   consul force-leave <node_name>
   ```
5. Verify the node rejoins the cluster:
   ```bash
   consul members
   ```

---

## Vault Alerts

### VaultSealed

**Severity**: 🔴 Critical (Instant — `for: 0m`)
**Fires when**: `vault_core_unsealed == 0` on any Vault node.

**Impact**: A sealed Vault cannot serve ANY secrets. All applications depending on Vault for credentials, certificates, or encryption will fail.

**Triage Steps**:
1. Check Vault status:
   ```bash
   vault status
   ```
2. If Vault restarted (e.g., after a deployment or crash), manually unseal:
   ```bash
   vault operator unseal <unseal_key_1>
   vault operator unseal <unseal_key_2>
   vault operator unseal <unseal_key_3>
   ```
3. If using auto-unseal (AWS KMS, Transit, etc.), check the seal mechanism:
   ```bash
   journalctl -u vault -f --grep "seal\|unseal\|kms"
   ```
4. Verify the auto-unseal KMS key is accessible and IAM permissions are correct.
5. If multiple nodes are sealed simultaneously, check for:
   - Network partition to KMS endpoint
   - IAM policy changes
   - KMS key deletion or disablement

**Prevention**: Use auto-unseal with AWS KMS or HashiCorp Transit. Monitor seal status in Grafana dashboard. Store unseal keys securely (e.g., Shamir shares in separate secure locations).

---

### VaultAuditLogFailure

**Severity**: 🔴 Critical (Instant — `for: 0m`)
**Fires when**: `vault_audit_log_request_failure > 0`.

**Impact**: **Vault blocks ALL requests** when audit logging fails. This is a security design decision — Vault refuses to operate without an audit trail.

**Triage Steps**:
1. Check Vault audit device status:
   ```bash
   vault audit list -detailed
   ```
2. Check the audit log destination:
   - **File**: Check disk space and file permissions on the audit log path.
   - **Syslog**: Verify the syslog daemon is running.
   - **Socket**: Verify the socket endpoint is reachable.
3. Check disk space on the Vault server:
   ```bash
   df -h
   ```
4. If disk is full, free space immediately (rotate/compress old audit logs):
   ```bash
   journalctl --vacuum-size=500M
   ```
5. If the audit device is permanently broken, disable and re-enable:
   ```bash
   vault audit disable file/
   vault audit enable file file_path=/var/log/vault/audit.log
   ```
6. Verify Vault is serving requests again:
   ```bash
   vault status
   vault token lookup
   ```

**Prevention**: Monitor disk space on Vault nodes. Set up log rotation for audit files. Use multiple audit devices (file + syslog) for redundancy — Vault only blocks if ALL audit devices fail.

---

## Infrastructure Alerts

### TargetDown

**Severity**: 🔴 Critical
**Fires when**: Prometheus `up` metric is `0` for > 2 minutes.

**Triage Steps**:
1. Identify the down target from the alert labels (`instance`, `job`).
2. Check if the service is running on that host:
   ```bash
   ssh <host> "systemctl status <service>"
   ```
3. Check network connectivity between Prometheus and the target.
4. If the service crashed, restart it and check logs for root cause.
5. If it's a configuration issue, verify the metrics endpoint is accessible:
   ```bash
   curl -s http://<instance>/v1/metrics?format=prometheus | head
   ```

---

### PrometheusConfigReloadFailed

**Severity**: 🔴 Critical
**Fires when**: `prometheus_config_last_reload_successful == 0` for > 1 minute.

**Triage Steps**:
1. Check Prometheus logs for YAML syntax errors:
   ```bash
   journalctl -u prometheus -f --grep "error\|reload"
   ```
2. Validate the configuration file:
   ```bash
   promtool check config /etc/prometheus/prometheus.yml
   ```
3. Validate alert rules:
   ```bash
   promtool check rules /etc/prometheus/prometheus_alert_rules.yml
   ```
4. Fix the syntax error and trigger a reload:
   ```bash
   kill -HUP $(pidof prometheus)
   ```

---

## Node / Host Alerts

### NodeDiskFull

**Severity**: 🔴 Critical
**Fires when**: Any non-tmpfs filesystem is > 95% full for > 5 minutes.

**Triage Steps**:
1. SSH into the affected host and identify what's consuming space:
   ```bash
   du -sh /* | sort -rh | head -20
   ```
2. Common space consumers:
   - **Docker**: `docker system prune -af`
   - **Logs**: `journalctl --vacuum-size=500M`
   - **Old packages**: `apt autoremove` / `yum autoremove`
3. If this is a data volume, consider expanding the disk (EBS volume resize, etc.).

### NodeOOMKillDetected

**Severity**: 🔴 Critical
**Fires when**: `node_vmstat_oom_kill` increases within 5 minutes.

**Triage Steps**:
1. Check which process was killed:
   ```bash
   dmesg | grep -i "oom\|killed process"
   ```
2. Review memory usage by process:
   ```bash
   ps aux --sort=-%mem | head -20
   ```
3. If a HashiCorp service was killed, restart it and consider increasing its memory allocation.
4. If recurring, add memory to the node or reduce workload density.

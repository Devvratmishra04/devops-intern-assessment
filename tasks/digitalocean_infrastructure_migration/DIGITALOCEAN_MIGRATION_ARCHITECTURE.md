# Digital Ocean Cloud Infrastructure Migration & Deployment Architecture

## 1. Executive Summary & Migration Context

This document outlines the architectural blueprint, network layout, security governance, and deployment orchestration for migrating core infrastructure services and data pipelines to a new **Digital Ocean** environment.

The migration establishes a highly available, private-isolated service mesh, resilient event-streaming backbone, centralized observability hub, and automated ETL ingestion pipelines extracting data from **Microsoft 365 / Azure AD**, **HubSpot CRM**, and **Salesforce CRM**.

---

## 2. Component Inventory & Acceptance Criteria Alignment

| Acceptance Component | Role in Architecture | DigitalOcean Deployment Mechanism | Resiliency / HA Strategy |
|---|---|---|---|
| **Bastion** | Hardened SSH/VPN ingress gateway into private VPC | Dedicated Droplet (`s-1vcpu-1gb`) with DO Cloud Firewall & fail2ban | Cloud-init automated provisioning, pubkey only |
| **Consul** | Service mesh, internal DNS (`*.service.consul`), KV store | 3-node server cluster + system client daemon on all workers | Raft consensus (quorum of 2/3), automatic leader failover |
| **Nomad** | Workload scheduler & cluster orchestrator | 3-node server quorum + auto-scaling client compute pool | Leader election, evaluation queue, automated task restarts |
| **Kafka** | Distributed message streaming platform & buffer | Nomad service job running Apache Kafka in KRaft mode | Partition replication, persistent host volume mounts, DLQ routing |
| **Grafana** | Unified observability, logging & metrics visualization | Nomad service job with pre-provisioned dashboards & datasources | Persistent storage, Consul DNS datasource discovery |
| **Microsoft Extraction** | Ingestion worker for Graph API (Users, Mail, Audit Logs) | Containerized Nomad job with delta sync checkpointing | Auto-reschedule, exponential backoff, DLQ fallback |
| **HubSpot Extraction** | Ingestion worker for HubSpot CRM (Contacts, Deals, etc.) | Containerized Nomad job with rate-limiting throttling (10 req/s) | Cursor-based pagination, Consul KV state persistence |
| **Salesforce Extraction** | Ingestion worker for Salesforce CRM (Leads, Accounts) | Containerized Nomad job with SOQL timestamp sync | OAuth2 refresh token renewal, error isolation |

---

## 3. Network Architecture & Security Isolation

### 3.1 Digital Ocean VPC Layout
All compute nodes (Consul, Nomad, Kafka, Grafana, and Extraction workers) are provisioned inside an isolated DigitalOcean Virtual Private Cloud (VPC) with CIDR `10.136.0.0/16`.

```
 Internet (Public Users / Administrators)
                  │
                  ▼ [Restricted Port 22 SSH]
        ┌──────────────────┐
        │  Bastion Host    │ Public IPv4 (Floating / Anchor)
        │ (10.136.1.10)    │ DigitalOcean Cloud Firewall
        └─────────┬────────┘
                  │ (SSH ProxyJump Tunnel)
══════════════════╪═════════════════════════════════════════════════════════
 DIGITAL OCEAN PRIVATE VPC (10.136.0.0/16) - NO PUBLIC INGRESS ALLOWED
──────────────────┼─────────────────────────────────────────────────────────
                  │
     ┌────────────┴─────────────┐
     │  Consul & Nomad Cluster  │
     │  (10.136.2.11 - 2.13)    │ Raft Quorum & Internal DNS (:8500, :4646)
     └────────────┬─────────────┘
                  │
                  ├──────────────────────────────┐
                  ▼                              ▼
     ┌─────────────────────────┐    ┌─────────────────────────┐
     │   Apache Kafka (KRaft)  │    │   Grafana Observability │
     │  (kafka.service.consul) │    │  (Port 3000 via Bastion)│
     └────────────▲────────────┘    └─────────────────────────┘
                  │
      ┌───────────┴───────────────────────────────┐
      │  Nomad-Scheduled Data Extraction Workers  │
      ├───────────────────┬───────────────────────┤
      │ [Microsoft Graph] │ [HubSpot CRM API]     │ [Salesforce SOQL]
      │ - Users & Mail    │ - Contacts & Deals    │ - Leads & Accounts
      │ - Delta Sync      │ - Rate Throttling     │ - OAuth2 Refresh
      └───────────────────┴───────────────────────┘
```

### 3.2 Security Firewall Policies
1. **Bastion Firewall (`bastion-fw`)**:
   - Inbound: Port 22 TCP restricted strictly to authorized administrator CIDRs (e.g. corporate VPN / static IPs).
   - Password authentication explicitly disabled (`PasswordAuthentication no`).
   - `fail2ban` active with 3-strike brute-force lockout.
2. **Internal Cluster Firewall (`internal-cluster-fw`)**:
   - Inbound SSH: Permitted ONLY from the Bastion host droplet ID.
   - Internal RPC / Gossip: Ports 8300-8302 (Consul), 4646-4648 (Nomad), 9092-9093 (Kafka) accessible strictly from `10.136.0.0/16`.
   - Direct public internet access is completely blocked for cluster nodes. Outbound internet egress is allowed for pulling container images and querying external SaaS APIs (Microsoft, HubSpot, Salesforce).

---

## 4. Kafka Event-Driven Ingestion Architecture

### 4.1 Topic Topology
Kafka operates in **KRaft mode**, eliminating the operational overhead and failure domains of Apache ZooKeeper. Topics are partitioned to allow parallel consumption:

- `extractions.microsoft`: 3 Partitions, 7-day retention (`168h`), snappy compression.
- `extractions.hubspot`: 3 Partitions, 7-day retention (`168h`), snappy compression.
- `extractions.salesforce`: 3 Partitions, 7-day retention (`168h`), snappy compression.
- `extractions.dlq`: Dead-letter queue for malformed payloads, schema validation errors, or network cutoffs.

### 4.2 State Management & Checkpointing
To ensure zero duplicate ingestion and disaster recovery:
- Extractors store cursor checkpoints (e.g. `users_delta_link`, `contacts_after`, `SystemModstamp`) in **Consul KV** (`extractions/<source>/<cursor_key>`).
- If Consul is momentarily unavailable during local testing, state stores fail over transparently to local persistent JSON files.

---

## 5. Observability & Monitoring Infrastructure

### 5.1 Grafana Dashboards
Two production dashboard definitions are provisioned in Grafana:
1. **DigitalOcean Cluster Overview (`do-cluster-overview`)**:
   - Bastion ingress network bandwidth and connection counts.
   - Consul Raft leader state and RPC latency.
   - Nomad active client allocations, running vs failed tasks.
   - Kafka under-replicated partitions (URP) and disk utilization.
2. **Extraction Telemetry Dashboard (`extractions-telemetry`)**:
   - Real-time ingestion rates (records/second) for Microsoft, HubSpot, and Salesforce.
   - Consumer lag across partition topics.
   - Dead-letter queue alert thresholds.

---

## 6. Migration Cutover & Operational Runbook

### Phase 1: Pre-Migration Validation
```bash
# Verify environment variables, SSH key presence, and configuration
py migration/migration_runner.py --dry-run
```

### Phase 2: Infrastructure Provisioning
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Phase 3: Service Mesh & Workload Deployment
```bash
# Submit Nomad job specifications
nomad job run nomad/consul.nomad
nomad job run nomad/kafka.nomad
nomad job run nomad/grafana.nomad
nomad job run nomad/microsoft-extraction.nomad
nomad job run nomad/hubspot-extraction.nomad
nomad job run nomad/salesforce-extraction.nomad
```

### Phase 4: Full Automated Verification
```bash
# Run acceptance criteria automated test suite
py migration/verify_migration.py
```

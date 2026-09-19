# Worker Resilience, Rate Limiting & Anti-Bot Testing Specification

## 1. Executive Summary

When deploying automated distributed workers or data pipeline crawlers against high-security endpoints (e.g., enterprise portals, social platforms), standard automation tooling frequently triggers automated anti-bot checkpoints. 

This document defines:
1. A **4-Layer Controlled Testing Methodology** to isolate and identify detection vectors.
2. **Mitigation Strategies** spanning network, TLS, browser runtime, and behavioral cadence.
3. A **Distributed Token-Bucket Architecture** backed by Redis Lua and Gaussian jitter to ensure workers remain under operational safety thresholds.

---

## 2. Multi-Tier Testing Methodology

To debug worker challenges or blocks methodically, run tests sequentially through four isolated layers:

```
[1. Network Layer] ──> [2. Fingerprint Layer] ──> [3. Automation Layer] ──> [4. Behavioral Layer]
   (IP / BGP / ASN)       (WebGL / Canvas / TLS)    (CDP / navigator.webdriver)   (Cursor / Jitter / Cadence)
```

### Phase A: Clean Automation Baseline
Ensure the automated browser instance does not leak automation telemetry before testing actual business logic.
* **Test Vector**: Run headless/headful workers against fingerprint auditing suites (e.g., *CreepJS*, *Buster*, *BrowserLeaks*).
* **Key Indicators**:
  * `navigator.webdriver` must evaluate to `false` or `undefined`.
  * `navigator.plugins`, `navigator.languages`, and `WebGLRenderer` strings must reflect realistic consumer hardware.
* **Mitigation**: Use hardened automation drivers, stealth extensions (e.g., `puppeteer-extra-plugin-stealth`, Playwright evasions), or custom Chromium patches.

### Phase B: Network Isolation
Evaluate network reputation independently of browser behavior.
* **Test Vector**: Execute identical requests across distinct proxy pools:
  * Control Group: Data center IP (AWS, GCP, DigitalOcean).
  * Test Group 1: Static Residential (ISP) proxy.
  * Test Group 2: 4G/5G Mobile proxy.
* **Key Indicators**: Instant CAPTCHA/checkpoint upon initial GET request indicates IP ASN flagging.
* **Mitigation**: 
  * Route worker egress through static residential (ISP) or mobile gateway proxies.
  * Avoid public datacenter CIDR ranges for authenticated sessions.

### Phase C: Cookie & Session Warm-Up
Separate session age/reputation from execution logic.
* **Test Vector**: Compare worker success rates when initiating raw credential login (`POST /login`) versus session cookie injection (`li_at`, `JSESSIONID`).
* **Key Indicators**: Checkpoints triggered during credential exchange vs. smooth navigation with persistent tokens.
* **Mitigation**:
  * Avoid automated logins inside ephemeral containers.
  * Pre-authenticate sessions in a controlled environment, persist session tokens in a secure secrets store (HashiCorp Vault / Redis), and inject them directly into the browser context.

### Phase D: Behavioral & Interaction Analysis
Evaluate in-page user telemetry.
* **Test Vector**: Monitor network events for client telemetry beacons (`/li/track`, `/csp/report`, sensor data bundles) transmitted during scrolling or clicking.
* **Key Indicators**: Challenges triggered after navigation or interaction despite passing network and fingerprint checks.
* **Mitigation**: Implement natural cursor trajectories and non-uniform pacing (see Section 3).

---

## 3. Advanced Mitigation Techniques

### 3.1 Real-Time Behavioral Humanization
Heuristic machine-learning models evaluate click intervals and cursor trajectories for mechanical uniformity.
* **Non-linear Cadence**: Discard fixed `sleep(2000)` pauses. Implement a Box-Muller Gaussian normal distribution with dynamic variance.
* **Curved Trajectories**: Use cubic or Bezier curves with organic acceleration, deceleration, and micro-overshoots (e.g., `ghost-cursor`).
* **Page Pacing**: Simulate human reading habits: scroll incrementally with varying velocity before triggering CTA clicks.

### 3.2 TLS / JA3 / JA4 Fingerprint Parity
Network edge proxies (Cloudflare, Akamai, custom ingress) evaluate the TLS `ClientHello` packet prior to parsing HTTP payloads.
* **The Problem**: Node.js `tls` or Python `urllib`/`requests` advertise cipher suites and TLS extension orders distinct from real browser engines.
* **Mitigation**:
  * Run tasks within real browser contexts via CDP/WebDriver where the OS/browser manages the native TLS handshake.
  * For raw API requests, use TLS-spoofing clients (e.g., `tls-client`, `curl-impersonate`) that mimic standard Chrome TLS Client Hello signatures.

---

## 4. Operational Safety Ceilings

When running automated pipelines on a per-account basis, enforce the following operational ceilings:

| Action / Metric | Conservative Ceiling (Daily) | Recommended Pacing |
| :--- | :--- | :--- |
| **Profile Views** | 80 – 100 / day | Distributed over 10–14 active hours |
| **Connection Requests** | 20 – 30 / day | Cap at $\le$ 100 / rolling week |
| **Direct InMail / Messages** | 40 – 50 / day | Minimum 3–5 min delay between dispatches |
| **Search Queries** | $\le$ 30 result pages / day | Vary query strings and search filters |

---

## 5. Distributed Architecture & Rate Limiting

To prevent race conditions across scaled containers, rate limits must be evaluated atomically in a centralized datastore (Redis).

```
                            ┌────────────────────────┐
                            │    Job Queue / SQS     │
                            └───────────┬────────────┘
                                        │
                      ┌─────────────────┴─────────────────┐
                      ▼                                   ▼
              ┌───────────────┐                   ┌───────────────┐
              │   Worker A    │                   │   Worker B    │
              └───────┬───────┘                   └───────┬───────┘
                      │                                   │
                      └───────────────┬───────────────────┘
                                      ▼
                      ┌───────────────────────────────┐
                      │    Redis Token Bucket (Lua)   │
                      │  - Atomic token consumption   │
                      │  - Account & action isolation │
                      └───────────────────────────────┘
```

### 5.1 Atomic Token Bucket (Redis Lua Script)
Save this script as `token_bucket.lua`:

```lua
-- KEYS[1]: Redis key, e.g. ratelimit:<account_id>:<action_type>
-- ARGV[1]: Max bucket capacity (burst threshold)
-- ARGV[2]: Refill rate per millisecond
-- ARGV[3]: Current timestamp in ms
-- ARGV[4]: Tokens requested (typically 1)

local key = KEYS[1]
local max_capacity = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local requested = tonumber(ARGV[4])

local bucket = redis.call('HMGET', key, 'tokens', 'last_updated')
local tokens = tonumber(bucket[1])
local last_updated = tonumber(bucket[2])

if not tokens then
    tokens = max_capacity
    last_updated = now
else
    local elapsed = math.max(0, now - last_updated)
    tokens = math.min(max_capacity, tokens + (elapsed * refill_rate))
    last_updated = now
end

if tokens >= requested then
    tokens = tokens - requested
    redis.call('HMSET', key, 'tokens', tokens, 'last_updated', last_updated)
    redis.call('PEXPIRE', key, 86400000) -- Expire after 24h of inactivity
    return 1 -- Token acquired
else
    redis.call('HMSET', key, 'tokens', tokens, 'last_updated', last_updated)
    return 0 -- Quota exhausted
end
```

### 5.2 Worker Integration & Gaussian Jitter (TypeScript Example)

```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

/**
 * Calculates randomized delay using Box-Muller Gaussian distribution.
 */
export function getGaussianDelay(
    meanMs: number,
    stdDevMs: number,
    minMs: number,
    maxMs: number
): number {
    let u1 = 0, u2 = 0;
    while (u1 === 0) u1 = Math.random();
    while (u2 === 0) u2 = Math.random();

    const standardNormal = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
    const randomizedDelay = Math.round(meanMs + standardNormal * stdDevMs);

    return Math.max(minMs, Math.min(maxMs, randomizedDelay));
}

/**
 * Executes an action with distributed token bucket pacing.
 */
export async function executeSafeWorkerAction(
    accountId: string,
    actionType: string,
    dailyLimit: number,
    actionCallback: () => Promise<void>
): Promise<boolean> {
    const key = `ratelimit:${accountId}:${actionType}`;
    
    // Refill rate over a 24-hour cycle (ms)
    const refillRatePerMs = dailyLimit / (24 * 60 * 60 * 1000);
    const burstCapacity = Math.min(10, Math.ceil(dailyLimit * 0.15));

    const tokenGranted = await redis.eval(
        LUA_TOKEN_BUCKET_SCRIPT,
        1,
        key,
        burstCapacity,
        refillRatePerMs,
        Date.now(),
        1
    );

    if (tokenGranted !== 1) {
        console.warn(`[Pacing] Account ${accountId} exceeded rate budget for ${actionType}. Re-queueing job.`);
        return false;
    }

    // Apply natural behavioral delay prior to dispatching action
    const cadenceDelay = getGaussianDelay(14000, 4000, 6000, 30000);
    await new Promise((resolve) => setTimeout(resolve, cadenceDelay));

    // Execute target workload
    await actionCallback();
    return true;
}
```

---

## 6. Observability & Alerting

Integrate Prometheus counters and Grafana dashboards to monitor pipeline health:
* `worker_checkpoint_encounters_total`: Tracks account challenge responses.
* `worker_token_exhaustions_total`: Indicates worker pool saturation.
* `worker_task_latency_seconds`: Measures Gaussian cadence distributions.

When `worker_checkpoint_encounters_total` spikes $\ge 2\%$ within a 1-hour window, initiate an automated circuit breaker to halt worker pools and trigger proxy/session audits.

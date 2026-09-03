# Papermark End-to-End Setup & Architectural Evaluation

## Task Overview
This task evaluates the end-to-end deployment, performance, scalability, and security architecture of **Papermark**—a modern TypeScript/Next.js open-source document sharing alternative to DocSend.

The objective was to audit the interaction between **Prisma ORM**, **PostgreSQL**, **NextAuth.js**, **S3/Cloudflare R2 storage**, and **Edge Middleware** to verify suitability for team-wide organizational rollout.

---

## Included Files & Structure

```
tasks/papermark_deployment_and_architecture/
├── README.md                                    # Quickstart, setup, smoke test & lessons learned
├── ARCHITECTURE_DEEP_DIVE.md                    # In-depth architectural exploration, KPIs & bottlenecks
├── schema_reference.prisma                      # Prisma ORM schema mapping (User, Document, Link, View, PageView)
├── docker-compose.papermark.yml                 # Self-hosted Docker stack (Next.js, Postgres 16, MinIO S3)
├── .env.example                                 # Complete environment variable configuration template
├── generate_docx.py                             # Automated Word report generation script
└── Papermark_Deployment_and_Architecture_Guide.docx # Professional Microsoft Word report
```

---

## Quickstart Deployment Guide

### Option 1: Self-Hosted Docker Compose (Recommended for Private On-Premise)

```bash
# 1. Navigate to task directory
cd tasks/papermark_deployment_and_architecture

# 2. Copy environment template
cp .env.example .env

# 3. Launch Docker Compose stack (Postgres + MinIO S3 + Papermark Web)
docker-compose -f docker-compose.papermark.yml up -d

# 4. Verify running containers
docker ps --filter "name=papermark"

# 5. Access Services:
# Web App:      http://localhost:3000
# MinIO S3 UI:  http://localhost:9001 (minioadmin / minioadminpass)
```

### Option 2: Cloud Deployment (Vercel + Supabase/Neon + Cloudflare R2)

1. **Database:** Create a PostgreSQL instance on Supabase or Neon.
2. **Storage:** Create a Cloudflare R2 bucket (`papermark-documents`) and generate S3 credentials.
3. **Environment:** Map variables from [.env.example](file:///c:/Internships/devops/tasks/papermark_deployment_and_architecture/.env.example) into the Vercel project settings.
4. **Deploy:** Push repository to trigger automatic Next.js build.

---

## Step-by-Step Smoke Test & Verification

1. **Document Upload Test:**
   - Log into the dashboard at `http://localhost:3000`.
   - Upload a standard 5MB PDF test document.
   - *Verification:* Document converts and uploads via presigned S3 PUT in **< 5 seconds**.

2. **Link Generation:**
   - Click **Share Document** and create a unique public link (e.g. `http://localhost:3000/d/sample-deck`).
   - Enable email gating or password protection if desired.

3. **Visitor Incognito Smoke Test:**
   - Open link in an Incognito / Private browser window.
   - Navigate through at least 3 distinct pages, pausing 5-10 seconds on each page.

4. **Analytics Verification:**
   - Return to creator dashboard.
   - *Verification:* The new **View** session appears in under **10 seconds**, displaying total duration, device type, country, and page-by-page retention metrics.

---

## Key Lessons Learned

1. **Presigned URLs Are Essential:** Direct client-to-S3 uploads are critical to circumvent serverless request size limitations (Vercel 4.5MB ceiling) and eliminate server network bottlenecks.
2. **Buffer Telemetry for High Concurrency:** Writing every page view directly to PostgreSQL via Prisma causes connection exhaustion during traffic spikes; high-scale production requires an event buffer (Tinybird or Redis) and PgBouncer connection multiplexing.
3. **Edge Middleware Powers Instant Geo-Tracking:** Leveraging CDN headers (`x-vercel-ip-country`, `cf-ipcountry`) eliminates third-party geolocation API latency and keeps Time-to-First-Byte (TTFB) well under 500ms.

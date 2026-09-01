# Scheduled SAST Delivery & Rollout Report Automation (DEV-460)

## Overview
This task establishes an automated reporting system to periodically dispatch the **SAST Delivery Status, Rollout Milestones, and Risk Analysis** directly to team communication channels (**Slack, Microsoft Teams, Discord**) and the GitHub Actions summary tab.

Based on ticket **[DEV-460: Proof of Concept – SAST Integration in CI/CD Pipeline](https://glynac.atlassian.net/browse/DEV-460)**.

---

## Included Files & Structure

```
tasks/sast_report_automation/
├── README.md                           # Quickstart & setup documentation
├── send_sast_report.py                 # Cross-platform webhook reporting script
├── SAST_REPORT_AUTOMATION_MANUAL.md    # Full technical implementation manual
├── generate_docx.py                    # Script to generate Word .docx guide
└── SAST_Report_Automation_Guide.docx   # Downloadable Microsoft Word report

.github/workflows/
└── sast_report_schedule.yml            # GitHub Actions cron workflow (Mondays 09:00 UTC)
```

---

## Delivery Status & Content Dispatched

- **Ticket:** DEV-460 (Status: Done)
- **Primary Tool:** Semgrep OSS (<10s scan, native SARIF)
- **Key Outcome:** 100% High/Critical vulnerability detection in Flask/Django test cases with <8s CI overhead.
- **Rollout Roadmap:**
  - **Phase 2 (Immediate):** Multi-Service Expansion across all remaining backend microservices (Non-blocking).
  - **Phase 3 (2-4 Weeks):** Developer Feedback & Rule Tuning via `.semgrepignore`.
  - **Phase 4 (End of Month):** Enforcement & Blocking Gate (`exit-code: 1`).
- **Risks Tracked:** Alert fatigue, Vault dependencies, scope creep.
- **Blockers:** None identified.

---

## How to Test Locally

### 1. Dry Run (Print to Console)
```bash
python tasks/sast_report_automation/send_sast_report.py --dry-run
```

### 2. Send to Slack / Teams / Discord
```bash
# Set your webhook URL
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/ORG/CHANNEL/TOKEN"
# or
export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
# or
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Run dispatcher
python tasks/sast_report_automation/send_sast_report.py
```

---

## Scheduled Automation Workflow

The workflow at `.github/workflows/sast_report_schedule.yml` runs automatically:
- **Recurring Schedule:** Every Monday at `09:00 AM UTC` (`0 9 * * 1`).
- **Manual Trigger:** On-demand via GitHub Actions `workflow_dispatch`.
- **Secret Integration:** Retrieves webhook tokens securely from **HashiCorp Vault** (`secret/data/ci/sast`).

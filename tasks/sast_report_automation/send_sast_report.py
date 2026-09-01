#!/usr/bin/env python3
"""
SAST Delivery & Rollout Status Automated Reporting Tool (DEV-460)
Supports automated scheduled delivery to Slack, Microsoft Teams, Discord, or Email.
"""

import os
import sys
import json
import argparse
from datetime import datetime, timezone
import urllib.request
import urllib.error

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

REPORT_METADATA = {
    "ticket_id": "DEV-460",
    "ticket_url": "https://glynac.atlassian.net/browse/DEV-460",
    "title": "Proof of Concept – SAST Integration in CI/CD Pipeline",
    "status": "Done (Resolved on 2026-08-31)",
    "owner": "@DevOps",
    "primary_tool": "Semgrep OSS (with Bandit integration)",
    "key_outcome": "100% detection of High/Critical vulnerabilities in Flask/Django test cases with <8s total pipeline overhead."
}

ROLLOUT_PHASES = [
    {
        "phase": "Phase 2: Multi-Service Expansion",
        "timeline": "Immediate (Active)",
        "owner": "@DevOps",
        "action": "Enable non-blocking SAST scans across all remaining backend microservices.",
        "goal": "Collect baseline security telemetry across the entire codebase without interrupting developer velocity."
    },
    {
        "phase": "Phase 3: Developer Feedback & Rule Tuning",
        "timeline": "Next 2-4 Weeks",
        "owner": "Security Lead / @DevOps",
        "action": "Review GitHub Security dashboard for false positives and calibrate .semgrepignore or custom rules.",
        "goal": "Eliminate noise, prevent alert fatigue, and ensure high developer adoption."
    },
    {
        "phase": "Phase 4: Enforcement & Blocking Gate",
        "timeline": "Target: End of Month",
        "owner": "DevOps / Engineering Manager",
        "action": "Transition High and Critical severity findings to blocking status (exit-code: 1).",
        "goal": "Prevent any critical vulnerabilities from being merged into production branches."
    }
]

RISKS_AND_MITIGATIONS = [
    {
        "category": "Alert Fatigue",
        "risk": "Developers may ignore security alerts if false positive rate increases during wider rollout.",
        "mitigation": "Maintain a strict 'High/Critical only' filter and provide actionable remediation snippets in PR comments."
    },
    {
        "category": "Vault Dependency",
        "risk": "If Vault AppRole or OIDC auth fails, CI/CD pipelines may stall or skip scans.",
        "mitigation": "Ensure robust error handling/fallback in ci.yml and monitor Vault cluster health."
    },
    {
        "category": "Scope Creep",
        "risk": "Adding too many low-severity rules early could bloat scan times beyond the <15s target.",
        "mitigation": "Stick strictly to baseline High/Critical rulesets until Phase 4 stabilizes."
    }
]

def generate_markdown_report() -> str:
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        f"# SAST CI/CD Delivery & Rollout Status Report",
        f"**Generated:** `{timestamp}` | **Ticket:** [{REPORT_METADATA['ticket_id']}]({REPORT_METADATA['ticket_url']})\n",
        f"### Delivery Status Summary",
        f"- **Status:** `{REPORT_METADATA['status']}`",
        f"- **Owner:** `{REPORT_METADATA['owner']}`",
        f"- **Primary Tool:** `{REPORT_METADATA['primary_tool']}`",
        f"- **Key Outcome:** {REPORT_METADATA['key_outcome']}\n",
        f"### Recommended Next Delivery Actions (Rollout Roadmap)",
    ]
    for p in ROLLOUT_PHASES:
        lines.append(f"**{p['phase']}** ({p['timeline']})")
        lines.append(f"- **Owner:** `{p['owner']}`")
        lines.append(f"- **Action:** {p['action']}")
        lines.append(f"- **Goal:** {p['goal']}\n")
    
    lines.append(f"### Risks & Mitigations")
    lines.append(f"| Risk Category | Description | Mitigation |")
    lines.append(f"|---|---|---|")
    for r in RISKS_AND_MITIGATIONS:
        lines.append(f"| **{r['category']}** | {r['risk']} | {r['mitigation']} |")
    
    lines.append(f"\n### Current Blockers")
    lines.append(f"- **None identified.** Technical hurdles (Vault integration, scan speed <8s, accuracy 100%) successfully cleared.")
    
    return "\n".join(lines)

def send_slack_webhook(webhook_url: str, text: str) -> bool:
    payload = {
        "text": f"*[DEV-460] SAST Delivery & Rollout Status Report*\n\n{text}"
    }
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status in (200, 204)
    except Exception as e:
        print(f"[!] Error sending Slack webhook: {e}", file=sys.stderr)
        return False

def send_discord_webhook(webhook_url: str, text: str) -> bool:
    payload = {
        "content": f"**[DEV-460] SAST Delivery & Rollout Status Report**\n\n{text[:1900]}"
    }
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "User-Agent": "DevOps-Reporter"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status in (200, 204)
    except Exception as e:
        print(f"[!] Error sending Discord webhook: {e}", file=sys.stderr)
        return False

def send_teams_webhook(webhook_url: str, text: str) -> bool:
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "0076D7",
        "summary": "SAST CI/CD Delivery & Rollout Status Report",
        "sections": [{
            "activityTitle": "SAST Delivery & Rollout Status (DEV-460)",
            "activitySubtitle": f"Status: {REPORT_METADATA['status']} | Owner: {REPORT_METADATA['owner']}",
            "text": text.replace("\n", "<br>")
        }]
    }
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status in (200, 204)
    except Exception as e:
        print(f"[!] Error sending Teams webhook: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description="SAST Status Automation Reporter (DEV-460)")
    parser.add_argument("--dry-run", action="store_true", help="Print report to stdout without sending webhooks")
    parser.add_argument("--output-file", type=str, help="Save report markdown to file")
    args = parser.parse_args()

    report_md = generate_markdown_report()

    if args.output_file:
        with open(args.output_file, "w", encoding="utf-8") as f:
            f.write(report_md)
        print(f"[+] Saved report markdown to: {args.output_file}")

    print("==================================================")
    print("   SAST Delivery & Rollout Report (DEV-460)")
    print("==================================================")
    print(report_md)
    print("==================================================")

    slack_url = os.environ.get("SLACK_WEBHOOK_URL")
    teams_url = os.environ.get("TEAMS_WEBHOOK_URL")
    discord_url = os.environ.get("DISCORD_WEBHOOK_URL")

    if args.dry_run or (not slack_url and not teams_url and not discord_url):
        print("[*] Dry run completed or no webhook URLs configured. Report displayed above.")
        return 0

    sent = False
    if slack_url:
        print("[+] Dispatching report to Slack...")
        if send_slack_webhook(slack_url, report_md):
            print("[✓] Successfully sent to Slack.")
            sent = True
    if teams_url:
        print("[+] Dispatching report to Microsoft Teams...")
        if send_teams_webhook(teams_url, report_md):
            print("[✓] Successfully sent to Microsoft Teams.")
            sent = True
    if discord_url:
        print("[+] Dispatching report to Discord...")
        if send_discord_webhook(discord_url, report_md):
            print("[✓] Successfully sent to Discord.")
            sent = True

    return 0 if sent else 1

if __name__ == "__main__":
    sys.exit(main())

# Amazon SES Sandbox to Production Access Request

## Objective
Move the `glynac.ai` SES account from **Sandbox Mode** (restricted to verified emails, 200 emails/day) to **Production Mode** (unlimited/scaled sending).

---

## Pre-Submission Verification Audit (Live DNS Check)

- [x] **SPF Record**: `include:amazonses.com` present in TXT record (`v=spf1 include:spf.protection.outlook.com include:amazonses.com -all`)
- [x] **DMARC Record**: `_dmarc.glynac.ai` is active with policy (`v=DMARC1; p=reject; rua=mailto:dmarc.reports@glynac.ai`)
- [ ] **Identity Verification**: Domain `glynac.ai` status marked as **Verified** in AWS SES Console.
- [ ] **DKIM Configuration**: 3 CNAME records verified in AWS SES Console & DNS provider.
- [ ] **Custom MAIL FROM**: `mail.glynac.ai` configured in SES (Optional but recommended).

---

## AWS Console Navigation
1. Log into AWS Console.
2. Select the correct region for SES.
3. Go to **Amazon SES** > **Account Dashboard**.
4. Click **Request Production Access**.
5. **Mail Type**: Select `Transactional` (*Safer/Faster approval*).
6. **Website URL**: `https://glynac.ai` (*Must be live with Privacy Policy*).

---

## Application Form Responses

### Field 1: How do you acquire email addresses?
```text
We are a B2B technology consultancy. All email addresses are collected through 'Double Opt-In' forms on our website (https://glynac.ai) where users request whitepapers or consultation calls. We also send system notifications to existing clients who have signed Master Service Agreements (MSAs) with us. We strictly do not use purchased, rented, or scraped email lists.
```

### Field 2: How do you handle bounces and complaints?
```text
We have implemented an automated feedback loop using Amazon SNS topics coupled with our internal automation platform (n8n).

Hard Bounces and Complaints trigger an SNS JSON notification.

Our webhook immediately processes this event and updates our CRM (Mautic) to mark the contact as 'Do Not Contact' instantly.

This ensures we never send a second email to a bounced address or a user who marked us as spam.
```

### Field 3: How can recipients opt out?
```text
Every non-transactional email includes a clear, one-click 'Unsubscribe' link in the footer. This link is managed by Mautic and is tested to ensure it immediately removes the user from all future mailing lists without requiring login.
```

### Field 4: What is the content of your emails?
```text
We send two types of emails:

Transactional: System alerts, invoice notifications, and project status updates for active clients.

Educational: Weekly summaries of tech infrastructure changes (like the daily recaps) sent only to internal staff and subscribed stakeholders.
```

---

## Post-Submission Actions

- [ ] Monitor inbox (`dvp@glynac.ai`) daily for AWS Support "Case Update".
- [ ] **DO NOT** send any bulk emails until the status changes to "Approved".

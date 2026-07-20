# Standard Operating Procedure (SOP)
## Amazon SES Production Access Request (Sandbox → Production)

### 1. Purpose
This SOP provides a clear, repeatable process to request Amazon Simple Email Service (SES) production access for the company AWS account. It ensures the request is submitted with all required prerequisites and best practices so approvals are smooth and future engineers can follow the same process.

### 2. Scope
This SOP applies to all company AWS accounts using Amazon SES that are currently in Sandbox mode and require sending emails to unverified recipients or require increased sending limits.

### 3. Definitions
- **Sandbox Mode**: SES restricted mode where emails can only be sent to verified identities with low quotas (restricted to only 200 emails per 24 hours).
- **Production Access**: SES mode allowing emails to be sent to any recipient, with higher quotas and rates.
- **Identity**: A verified email address or domain in SES used as the sender.
- **DKIM**: DomainKeys Identified Mail; improves email authenticity and deliverability.
- **SPF**: Sender Policy Framework; DNS record authorizing senders for a domain.
- **DMARC**: Policy framework that aligns SPF/DKIM and provides reporting and enforcement options.

---

### 4. Roles and Responsibilities
- **Requestor (Engineer/Administrator)**: Completes prerequisites, submits request, and responds to AWS follow-ups.
- **Cloud/DevOps Lead**: Reviews request content for accuracy and compliance before submission.
- **Security/Compliance (if applicable)**: Validates opt-in/opt-out practices and email content compliance.

---

### 5. Prerequisites
- Access to the correct company AWS account.
- Correct AWS Region selected for SES usage (SES is region-specific).
- IAM permissions to manage SES identities and submit support requests.
- Company domain available and DNS access (Route 53 or external DNS provider).
- Domain identity verified in SES (recommended).
- DKIM enabled for the domain identity (recommended).
- Bounce and complaint handling configured using SNS (recommended).
- Estimated sending volume and use-case information prepared.

---

### 6. Procedure: Request Production Access

#### 6.1 Confirm SES Sandbox Status
Open AWS Console → Amazon SES → Account dashboard. Confirm the account is in Sandbox mode for the selected region.

#### 6.2 Verify Sender Identity (Recommended)
Go to SES → Verified identities. Verify the company domain identity and ensure DKIM is enabled. Confirm SPF and (optionally) DMARC are configured in DNS.

#### 6.3 Configure Bounce and Complaint Handling (Recommended)
Create SNS topics for bounce and complaint notifications (e.g., `ses-bounce-topic`, `ses-complaint-topic`). Attach these topics to the SES identity. Subscribe an internal distribution list or a Lambda processor.

#### 6.4 Open Production Access Request
From SES → Account dashboard, select **Request production access**.

#### 6.5 Complete Request Form (Approval-Safe Guidance)
Fill the form with clear, non-spammy details. Recommended responses are included in Section 7.

#### 6.6 Submit Request
Submit the request. Monitor email/support case for follow-up questions. Respond promptly with details if requested.

#### 6.7 Post-Approval Validation
After approval, confirm Production status in SES Account dashboard and verify quotas. Perform controlled test sends and validate monitoring/alerts are active.

---

### 7. Recommended Request Form Template (Copy/Paste)
- **Mail Type**: Transactional
- **Website URL**: https://www.glynac.ai
- **Field 1: How do you acquire email addresses?**
  > "We are a B2B technology consultancy. All email addresses are collected through 'Double Opt-In' forms on our website (Glynac — AI-Powered Wealth Management) where users request whitepapers or consultation calls. We also send system notifications to existing clients who have signed Master Service Agreements (MSAs) with us. We strictly do not use purchased, rented, or scraped email lists."
- **Field 2: How do you handle bounces and complaints?**
  > "We have implemented an automated feedback loop using Amazon SNS topics coupled with our internal automation platform (n8n). Hard Bounces and Complaints trigger an SNS JSON notification. Our webhook immediately processes this event and updates our CRM (Mautic) to mark the contact as 'Do Not Contact' instantly. This ensures we never send a second email to a bounced address or a user who marked us as spam."
- **Field 3: How can recipients opt out?**
  > "Every non-transactional email includes a clear, one-click 'Unsubscribe' link in the footer. This link is managed by Mautic and is tested to ensure it immediately removes the user from all future mailing lists without requiring login."
- **Field 4: What is the content of your emails?**
  > "We send two types of emails: Transactional (System alerts, invoice notifications, and project status updates for active clients) and Educational (Weekly summaries of tech infrastructure changes sent only to internal staff and subscribed stakeholders)."

---

### 8. Do’s and Don’ts

#### 8.1 Do’s
- Start with **Transactional** mail type for first approval whenever possible.
- Verify a domain identity and enable DKIM before requesting production access.
- Implement bounce/complaint handling using SNS (and Lambda/n8n automation).
- Keep initial sending volume conservative and scale gradually.
- Clearly describe recipient opt-in and compliance practices.
- Monitor sending metrics in CloudWatch and maintain low bounce/complaint rates.

#### 8.2 Don’ts
- Do not claim very high volumes (e.g., millions/day) during initial approval.
- Do not use purchased, rented, or scraped email lists.
- Do not submit vague use-case descriptions without opt-in explanation.
- Do not skip bounce/complaint handling planning.
- Do not send marketing emails without unsubscribe mechanisms and clear consent.

---

### 9. Common Approval Delays / Rejections
- Unclear opt-in or consent process.
- Marketing/bulk email use case without unsubscribe and compliance details.
- No bounce/complaint handling plan.
- Unverified domain or missing DKIM configuration.
- Unrealistic sending volume estimates.
- Incomplete or inconsistent request information.

---

### 10. Pre-Submission Checklist
- [ ] Correct AWS account and SES region confirmed.
- [ ] Domain identity verified in SES.
- [ ] DKIM enabled and DNS records published.
- [ ] SPF record validated; DMARC configured if required by policy.
- [ ] Sending volume estimate prepared and realistic.
- [ ] Use-case and opt-in/opt-out details reviewed by DevOps Lead.

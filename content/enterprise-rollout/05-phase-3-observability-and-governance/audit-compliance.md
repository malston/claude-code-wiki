---
title: "Audit and Compliance -- Three-Layer Architecture"
linkTitle: "Audit & Compliance"
weight: 1
---

# Audit and Compliance -- Three-Layer Architecture

## Layer 1: AWS CloudTrail

Captures every Bedrock `InvokeModel` call with IAM principal attribution.

**What it records:**

- Timestamp of every API call
- IAM principal (which user/role made the call)
- Model ID invoked
- Source IP address
- Request parameters (not prompt content by default)

**Configuration:**

- Enable CloudTrail in the dedicated Bedrock AWS account
- Send logs to a centralized S3 bucket with immutable retention policy
- Set up CloudWatch Alarms for unusual patterns (e.g., API calls outside business hours, unexpected model IDs)

**Limitation:** CloudTrail records that a call was made but not what was asked or returned. It's an access log, not a content log.

## Layer 2: LLM Gateway Logs

The gateway logs request metadata with more granularity than CloudTrail.

**What it records:**

- Authenticated user identity (SSO principal)
- Timestamp and duration
- Model requested
- Token count (input and output)
- Latency
- Team/project attribution (from request headers or SSO claims)
- Request status (success, error, rate-limited)

**What it should NOT record (if ZDR is active):**

- Prompt content
- Response content
- Code snippets from requests

**Configuration:**

- Send structured logs to your SIEM or log aggregation platform
- Retention period aligned with your data retention policy (typically 90 days for metadata)
- Access restricted to security and compliance teams

## Layer 3: Bedrock Model Invocation Logging

Bedrock offers opt-in model invocation logging that captures full prompt and response content -- the content-level audit trail that CloudTrail and gateway metadata logs don't provide.

**What it records (when enabled):**

- Full prompt content (what was sent to the model)
- Full response content (what the model returned)
- Token counts, latency, and model metadata

**Destinations:**

- CloudWatch Logs (for events up to 100KB)
- S3 (for larger payloads and long-term retention)

**When to enable:**

- Regulatory environments requiring content-level audit trail
- Incident investigation (what exactly did Claude generate?)
- Compliance audits requiring evidence of AI-generated output

**When NOT to enable:**

- If Zero Data Retention (ZDR) is a requirement -- invocation logging stores prompt content
- If logging code snippets to CloudWatch/S3 creates a new data residency concern

**Configuration:**

- Enable via Bedrock console or API (`PutModelInvocationLoggingConfiguration`)
- Set S3 bucket with immutable retention policy for audit trail
- Restrict access to compliance/security teams via IAM

**Anthropic Direct vs. Bedrock Audit Paths**

Anthropic offers a Compliance API for Claude for Enterprise (direct API) customers. It provides programmatic access to usage data, activity logs, conversation histories, and selective deletion, with filtering by user and time range. Compliance teams can integrate this into existing monitoring workflows through a single API integration point.

This API does **not** apply to Bedrock. When using Bedrock, Anthropic has no access to your requests -- AWS handles all inference in isolation. The three-layer AWS-native stack described on this page (CloudTrail + Gateway + Invocation Logging) provides equivalent audit capabilities through AWS tooling.

For clients evaluating both deployment paths: the Compliance API is a simpler audit integration (one API, one vendor) but requires the Anthropic Enterprise plan and direct API access. The Bedrock path offers deeper integration with existing AWS security infrastructure (IAM, CloudWatch, S3 lifecycle policies) at the cost of building and maintaining the three-layer stack yourself.

## Compliance Mapping

| Requirement                            | Control                                       | Layer                    |
| -------------------------------------- | --------------------------------------------- | ------------------------ |
| Who accessed the AI service?           | IAM principal logging                         | CloudTrail               |
| What model was used?                   | Model ID in API call                          | CloudTrail + Gateway     |
| How much was consumed?                 | Token counting                                | Gateway                  |
| Was any sensitive data exposed?        | Deny rules in managed-settings.json           | Preventive (Phase 1)     |
| Can we prove no data left our network? | VPC Flow Logs + PrivateLink config            | Infrastructure (Phase 0) |
| Can we delete a user's data?           | S3 lifecycle rules + CloudWatch log retention | Invocation Logging (AWS) |
| Are sessions auto-purged?              | cleanupPeriodDays in managed-settings         | Preventive (Phase 1)     |

## Regulatory Framework Alignment

### SOC 2

- CloudTrail provides the access logging control
- Gateway provides usage monitoring and anomaly detection
- Managed settings provide the access control policy
- All three together satisfy the monitoring and logging requirements

### HIPAA

- VPC PrivateLink ensures PHI never traverses public internet
- Deny rules prevent Claude from reading files in PHI-containing paths
- cleanupPeriodDays ensures session transcripts don't persist on developer machines
- BAA with AWS covers Bedrock; confirm coverage scope with AWS

### GDPR

- Data subject deletion: S3 lifecycle policies on invocation logs, CloudWatch log retention settings, `cleanupPeriodDays` for local session transcripts
- Gateway metadata retention aligned with GDPR data minimization
- No prompt content logging unless invocation logging is explicitly enabled
- Anthropic has no access to Bedrock requests, simplifying the data processor relationship (your DPA is with AWS, not Anthropic)

### SOX (Financial Services)

- CloudTrail immutable logs for audit trail
- Gateway enforces segregation of duties (model access by role)
- Managed settings prevent bypass of controls

### ISO/IEC 42001:2023

Anthropic holds ISO/IEC 42001:2023 certification (effective January 2025, audited by Schellman Compliance LLC). ISO 42001 is the first international standard for AI management systems -- more specifically relevant for enterprises evaluating AI tooling than the general-purpose ISO 27001 infosec certification. Anthropic also maintains ISO 27001:2022 and SOC 2 Type I & II certifications.

_Last validated against Claude Code docs: 2026-03-20_

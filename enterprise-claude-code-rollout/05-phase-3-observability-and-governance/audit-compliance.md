# Audit and Compliance — Three-Layer Architecture

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

**Note:** Anthropic offers a separate Compliance API for Claude for Enterprise (direct API) customers, but it does **not** apply to Bedrock. When using Bedrock, Anthropic has no access to your requests -- AWS handles all inference in isolation. Your audit tooling is entirely AWS-native.

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

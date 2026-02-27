---
title: "Reference Configurations"
weight: 3
---

# Reference Configurations

## managed-settings.json (Enterprise Baseline)

Deploy to all developer machines via MDM.

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://llm-gateway.internal.corp.com/bedrock",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "cleanupPeriodDays": 14,
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/.ssh/**)",
      "Read(**/credentials*)",
      "Bash(sudo:*)",
      "Bash(su:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(ssh:*)",
      "Bash(rm -rf:*)"
    ]
  },
  "allowManagedPermissionRulesOnly": false,
  "allowManagedHooksOnly": false,
  "strictKnownMarketplaces": []
}
```

### File Locations

| Platform | Path                                                            |
| -------- | --------------------------------------------------------------- |
| macOS    | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux    | `/etc/claude-code/managed-settings.json`                        |
| Windows  | `C:\Program Files\ClaudeCode\managed-settings.json`             |

## Developer Shell Environment Variables

```bash
# /etc/profile.d/claude-code.sh

# Bedrock routing (also set in managed-settings.json env)
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_BEDROCK_BASE_URL='https://llm-gateway.internal.corp.com/bedrock'
export CLAUDE_CODE_SKIP_BEDROCK_AUTH=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Corporate CA cert for proxy (if applicable)
export NODE_EXTRA_CA_CERTS='/etc/ssl/certs/corp-ca-bundle.pem'

# Optional: Model overrides
# export ANTHROPIC_MODEL='claude-sonnet-4-5-20250929'
# export ANTHROPIC_DEFAULT_HAIKU_MODEL='us.anthropic.claude-haiku-4-5-20251001-v1:0'
```

## Terraform: VPC Endpoint for Bedrock

```hcl
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.bedrock_endpoint.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "bedrock_endpoint" {
  name_prefix = "bedrock-endpoint-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.developer_subnet_cidrs
    description = "Allow HTTPS from developer subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## IAM Policy for Bedrock Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListInferenceProfiles"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach to the IAM role used by the LLM gateway service, not to individual developer users.

## Sample Project .claude/settings.json

```json
{
  "permissions": {
    "allow": [
      "Read(src/**)",
      "Read(tests/**)",
      "Read(docs/**)",
      "Bash(npm test:*)",
      "Bash(npm run lint:*)",
      "Bash(go test:*)"
    ],
    "deny": ["Read(**/patient-data/**)", "Bash(docker push:*)"]
  }
}
```

## Sample .mcp.json (Project MCP Servers)

MCP servers are sourced from the community, vendor-maintained packages, or built internally. Verify package names against the MCP server registry before deploying. The examples below use placeholder package names.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/dir"
      ],
      "env": {}
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://readonly@db.internal.corp:5432/staging"
      }
    }
  }
}
```

For enterprise integrations (Jira, Sentry, Datadog), check whether the vendor provides an official MCP server or build one internally using the `@modelcontextprotocol/sdk` TypeScript SDK.

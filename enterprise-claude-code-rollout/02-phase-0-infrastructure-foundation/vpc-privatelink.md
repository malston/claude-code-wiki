# VPC Endpoint and PrivateLink Architecture

## Purpose

Create a private connection between the corporate VPC and Amazon Bedrock. No internet gateway, no NAT, no public IPs needed. All traffic between the enterprise network and Bedrock stays within AWS's private backbone.

## Key Terraform Resources

```hcl
# VPC Endpoint for Bedrock Runtime
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

# Security group: only allow traffic from developer subnets
resource "aws_security_group" "bedrock_endpoint" {
  name_prefix = "bedrock-endpoint-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.developer_subnet_cidrs
  }
}
```

## Design Decisions

### Private DNS Enabled

With `private_dns_enabled = true`, Claude Code's standard Bedrock URLs resolve internally to the VPC endpoint's private IP addresses. No application-level configuration changes needed beyond enabling Bedrock mode.

### Endpoint Policy Scoping

The VPC endpoint policy is scoped to **only** `InvokeModel` and `InvokeModelWithResponseStream`. This prevents the endpoint from being used for other Bedrock operations (model management, training jobs, etc.) — defense in depth.

### Security Group Restrictions

Traffic to the endpoint is restricted to developer subnet CIDRs only. In practice, if using an LLM gateway, the security group should allow traffic from the gateway's subnet, not individual developer subnets directly.

### Corporate Network Connectivity

The corporate network connects to the VPC via:

- **AWS Direct Connect** (preferred for production): Dedicated private connection
- **Site-to-Site VPN** (acceptable for initial setup): Encrypted tunnel over internet

## Dedicated AWS Account

Isolate the Bedrock usage into its own account within the org's AWS Control Tower. Benefits:

- **Cost attribution:** All Bedrock costs are in one account, simple to track
- **IAM boundaries:** Separate IAM policies from production workloads
- **Audit scoping:** CloudTrail and compliance reporting scoped to the Bedrock account
- **Blast radius:** If something goes wrong with AI infrastructure, it doesn't affect production systems

## Validation Checklist

- [ ] VPC endpoint resolves Bedrock URLs to private IPs (test with `nslookup`)
- [ ] Security group allows traffic only from expected source subnets
- [ ] CloudTrail logging enabled for all Bedrock API calls
- [ ] Direct Connect / VPN connection verified with latency < 50ms
- [ ] Claude Code successfully invokes model through the private path
- [ ] No public internet egress observed in VPC flow logs during Claude Code usage

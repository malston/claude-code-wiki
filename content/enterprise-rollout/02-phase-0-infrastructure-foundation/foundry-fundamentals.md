---
title: "Azure Foundry Fundamentals"
weight: 3
---

# Azure Foundry Fundamentals

## What Is Azure AI Foundry?

Azure AI Foundry (also called Microsoft Foundry) is Microsoft's managed AI platform. Anthropic's Claude models are available as partner models through Foundry, giving you an Azure-native API that uses the same Entra ID, billing, networking, and compliance infrastructure you already use for everything else in Azure.

**Analogy for Cloud Foundry practitioners:** Same abstraction as Bedrock -- developers call an API, the platform team controls networking, access, cost, and compliance underneath. The difference is which cloud's control plane you're working with.

## Key Properties for Enterprise Deployment

### Managed Inference, Not Model Hosting

You don't deploy models or manage GPU clusters. You create a model deployment in your Azure AI Foundry resource, and Azure handles inference. Azure runs the Claude models in their infrastructure under a contractual relationship with Anthropic.

### Data Boundary Guarantees

- Customer inputs and outputs are **not** used to train or improve foundation models
- Data is **not** shared with model providers (Anthropic)
- Data is **not** stored beyond immediate request processing (unless you explicitly enable logging)
- Your code/prompts go to Azure, not to Anthropic directly

### Inherits the Azure Security Stack

- **Entra ID (Azure AD)** controls who can invoke which models (`Azure AI User` or `Cognitive Services User` roles)
- **Azure Activity Log** logs every API call
- **Private Endpoints** keep traffic off the public internet
- **Customer-managed keys** for data at rest
- **Compliance certifications:** SOC 2, ISO 27001, HIPAA, FedRAMP, etc.

### Pricing Model

- **On-demand:** Pay-per-token at Anthropic's standard API pricing (no Azure markup)
- Claude models are third-party marketplace items -- Azure credits from programs like Microsoft for Startups **cannot** be applied

## How Claude Code Talks to Azure Foundry

Setting `CLAUDE_CODE_USE_FOUNDRY=1` switches Claude Code from calling `api.anthropic.com` to using the Azure AI Foundry endpoint. The Claude models are the same -- same Sonnet, same Opus, same capabilities -- but the request path changes:

```text
Without Foundry:
  developer laptop -> internet -> api.anthropic.com -> Claude model

With Foundry:
  developer laptop -> corporate network -> Azure AI endpoint -> Claude model (in Azure)

With Foundry + Private Endpoint:
  developer laptop -> corporate network -> Private Endpoint -> Azure AI -> Claude
  (nothing touches the public internet at any point)
```

### Environment Variables

#### Required

| Variable                     | Example          | Purpose                           |
| ---------------------------- | ---------------- | --------------------------------- |
| `CLAUDE_CODE_USE_FOUNDRY`    | `1`              | Enables Azure Foundry integration |
| `ANTHROPIC_FOUNDRY_RESOURCE` | `my-ai-resource` | Azure AI resource name            |

**Or alternatively** (mutually exclusive with `ANTHROPIC_FOUNDRY_RESOURCE`):

| Variable                     | Example                                                  | Purpose           |
| ---------------------------- | -------------------------------------------------------- | ----------------- |
| `ANTHROPIC_FOUNDRY_BASE_URL` | `https://my-ai-resource.services.ai.azure.com/anthropic` | Full endpoint URL |

#### Optional

| Variable                         | Example             | Purpose                                                              |
| -------------------------------- | ------------------- | -------------------------------------------------------------------- |
| `ANTHROPIC_FOUNDRY_API_KEY`      | API key             | For API key auth; when absent, uses Azure SDK DefaultAzureCredential |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `claude-sonnet-4-5` | Overrides the primary Sonnet model                                   |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL`  | `claude-haiku-4-5`  | Overrides the Haiku model                                            |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`   | `claude-opus-4-6`   | Overrides the Opus model                                             |
| `ANTHROPIC_MAX_TOKENS`           | `100000`            | Per-request token limit                                              |
| `CLAUDE_CODE_SKIP_FOUNDRY_AUTH`  | `1`                 | Skips Foundry auth prompt (for CI/CD)                                |

**Important:** All three model env vars (`SONNET`, `HAIKU`, `OPUS`) should be set even if you're only using one model tier, to prevent fallback errors.

### API Endpoint Format

```text
https://{resource-name}.services.ai.azure.com/anthropic/v1/messages
```

### Dual-Model Usage

Claude Code uses **two models simultaneously:**

- **Primary model** (Sonnet or Opus): Heavy reasoning, code generation, analysis
- **Fast model** (Haiku): Lightweight tasks -- summarization, classification, quick checks

Both must be deployed in your Azure AI Foundry resource.

### Model IDs

Deployment names on Foundry match the model IDs:

| Model             | Deployment Name     |
| ----------------- | ------------------- |
| Claude Opus 4.6   | `claude-opus-4-6`   |
| Claude Opus 4.5   | `claude-opus-4-5`   |
| Claude Sonnet 4.5 | `claude-sonnet-4-5` |
| Claude Haiku 4.5  | `claude-haiku-4-5`  |

**Gotcha:** Deployment names **cannot be changed** after creation. Choose carefully during initial setup.

## Region Availability

Claude models on Azure Foundry are currently available as **Global Standard** deployments. Available regions:

- **East US 2**
- **Sweden Central**

Additional regions may require quota requests. Check the Azure AI Foundry portal for current availability.

## Subscription and Quota Requirements

### Enterprise Subscription Required

Claude models on Azure Foundry require an **Enterprise Agreement (EA)** or **Microsoft Customer Agreement - Enterprise (MCA-E)** subscription. The following subscription types are restricted:

- Cloud Solution Providers (CSP)
- Sponsored accounts with Azure credits
- Enterprise accounts in Singapore and South Korea
- Microsoft accounts (personal)

### Default Rate Limits

| Model             | RPM   | TPM       |
| ----------------- | ----- | --------- |
| Claude Opus 4.6   | 2,000 | 2,000,000 |
| Claude Sonnet 4.5 | 4,000 | 2,000,000 |
| Claude Haiku 4.5  | 4,000 | 4,000,000 |

Non-enterprise subscriptions receive **0 default quota** and must request an increase through the Azure portal.

### Requesting Quota Increases

1. Navigate to: Azure Portal -> Foundry resource -> Quotas
2. Request quota for the desired Claude model
3. Priority given to customers actively consuming existing quota
4. Approval typically takes 24--48 hours

## Known Gotchas

### Rate Limit Headers

Rate limit headers (`anthropic-ratelimit-*`) are **not included** in Foundry API responses, unlike the direct Anthropic API. If your LLM gateway or client code relies on these headers for rate limiting logic, it will need adjustment.

### Unsupported APIs

The following Anthropic APIs are not available through Foundry:

- Message Batch API
- Models API
- Admin API

### Authentication

The `/login` and `/logout` commands are disabled in Claude Code when using Foundry. Authentication is handled through Azure credentials (`az login` or `DefaultAzureCredential`).

### Tool Use Validation

Azure validates `tool_use`/`tool_result` message pairing more strictly than the direct Anthropic API. This can cause issues with conversation compacting in some configurations. Test thoroughly during Cohort 1.

### Portal Limitations

The Azure AI Foundry portal does not support end-to-end network isolation configuration. Use the Azure CLI, SDK, or Terraform for private endpoint and VNet setup.

## Private Endpoints and VNet Integration

This is the Azure equivalent of AWS VPC PrivateLink. Private Endpoints create a private IP address for your Azure AI resource within your VNet, keeping all traffic off the public internet.

### Architecture

```sh
┌──────────────────────────────────────────────────────┐
│  Azure VNet                                          │
│                                                      │
│  ┌──────────────────┐    ┌─────────────────────────┐ │
│  │ Developer VMs /  │    │ Private Endpoint        │ │
│  │ AKS Cluster      │───>│ (10.x.x.x)              │ │
│  │                  │    │                         │ │
│  └──────────────────┘    │  -> Azure AI Foundry    │ │
│                          │     resource            │ │
│                          └─────────────────────────┘ │
│                                                      │
│  NSG: allow 443 from developer subnets only          │
│                                                      │
└──────────────────────────────────────────────────────┘
           │
    ExpressRoute / Site-to-Site VPN
           │
    ┌──────────────┐
    │ Corporate    │
    │ Network      │
    └──────────────┘
```

### Key Terraform Resources

```hcl
# Azure AI resource (Cognitive Services account with AIServices kind)
resource "azurerm_cognitive_account" "claude" {
  name                  = "claude-ai-${var.environment}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = "claude-ai-${var.environment}"

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Deny"
    ip_rules       = []
    bypass         = "AzureServices"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Private DNS zone for Azure AI Services
resource "azurerm_private_dns_zone" "cognitive" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = var.resource_group_name
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "cognitive" {
  name                  = "cognitive-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive.name
  virtual_network_id    = var.vnet_id
}

# Private endpoint
resource "azurerm_private_endpoint" "claude" {
  name                = "claude-ai-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "claude-ai-psc"
    private_connection_resource_id = azurerm_cognitive_account.claude.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "cognitive-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cognitive.id]
  }
}

# NSG: only allow traffic from developer subnets
resource "azurerm_network_security_group" "claude_endpoint" {
  name                = "claude-ai-endpoint-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowDeveloperSubnets"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.developer_subnet_cidrs
    destination_address_prefix = "*"
  }
}

# Associate NSG with private endpoint subnet
resource "azurerm_subnet_network_security_group_association" "claude_endpoint" {
  subnet_id                 = var.private_endpoint_subnet_id
  network_security_group_id = azurerm_network_security_group.claude_endpoint.id
}
```

### Design Decisions

#### Custom Subdomain Required

The `custom_subdomain_name` parameter is **mandatory** for private endpoint connectivity. Without it, private endpoint attachment fails.

#### Network ACLs with Deny Default

Setting `default_action = "Deny"` on the Cognitive Services account ensures that only traffic through the private endpoint (and Azure services, via bypass) can reach the resource. All public internet access is blocked.

#### NSG on Private Endpoint Subnet

NSG support for private endpoints is available in most Azure regions. Apply NSG rules to the subnet hosting the private endpoint to restrict traffic to developer subnets only.

### Dedicated Resource Group

Isolate the Azure AI Foundry resource into its own resource group. Benefits:

- **Cost attribution:** All Claude costs in one resource group, simple to track with Azure Cost Management
- **RBAC boundaries:** Separate role assignments from production workloads
- **Audit scoping:** Activity Log filtered to the Claude resource group
- **Blast radius:** AI infrastructure issues don't affect production systems

### Validation Checklist

- [ ] Private endpoint resolves Azure AI resource URL to private IP (test with `nslookup`)
- [ ] NSG allows traffic only from expected source subnets on port 443
- [ ] Azure Activity Log enabled for the Cognitive Services account
- [ ] ExpressRoute / VPN connection verified with latency < 50ms
- [ ] Claude Code successfully invokes model through the private path
- [ ] Public network access disabled on the Cognitive Services account
- [ ] `custom_subdomain_name` configured on the account

## Gateway Deployment on Azure

The LLM gateway pattern is the same regardless of cloud provider -- see [LLM Gateway Design](../llm-gateway/) for the full rationale. This section covers Azure-specific deployment details.

### Developer-Facing Configuration

```bash
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_BASE_URL='https://llm-gateway.internal.corp.com/foundry'
export CLAUDE_CODE_SKIP_FOUNDRY_AUTH=1
# Gateway handles Azure auth; Claude Code skips direct Foundry auth
```

### Deployment Topology

```sh
┌─────────────────────────────────────┐
│  LLM Gateway (internal service)     │
│                                     │
│  Deployment: Container Apps or AKS  │
│  URL: llm-gateway.internal.corp     │
│  Auth: SSO / OIDC (Entra ID)        │
│                                     │
│  Upstream: Private Endpoint         │
│  (to Azure AI Foundry resource)     │
└─────────────────────────────────────┘
```

### Credential Management via Managed Identities

The gateway authenticates to Azure AI Foundry using **managed identities** -- no credentials stored in config.

**For Azure Container Apps:** Enable system-assigned managed identity on the Container App, then assign `Cognitive Services User` role on the Azure AI resource.

**For AKS:** Use Azure Workload Identity (successor to Pod Identity). Create a Kubernetes ServiceAccount federated with an Azure managed identity that has `Cognitive Services User` role.

### Azure-Specific Observability

Push **OpenTelemetry metrics** to Azure Monitor:

- Per-user token consumption
- Latency percentiles (p50, p95, p99)
- Error rates by model and user
- Request volume over time
- Budget utilization per team

## Corporate Network Connectivity

| Option                             | Bandwidth                   | Description                                                  |
| ---------------------------------- | --------------------------- | ------------------------------------------------------------ |
| **ExpressRoute**                   | 50 Mbps--100 Gbps           | Dedicated private connection through a connectivity provider |
| **Site-to-Site VPN**               | Up to 10 Gbps (VPN Gateway) | Encrypted IPsec tunnels over the internet                    |
| **ExpressRoute with VPN failover** | Combined                    | ExpressRoute primary, VPN as backup                          |

For enterprise Azure AI deployments, ExpressRoute is recommended to keep AI inference traffic off the public internet.

### Redundancy

- **Redundant connections:** Two ExpressRoute circuits from different peering locations, or ExpressRoute + Site-to-Site VPN as backup
- **Monitoring:** Azure Monitor alerts on ExpressRoute circuit status and VPN gateway health
- **Failover testing:** Test failover quarterly

## Provider Comparison

For a side-by-side comparison of Bedrock, Vertex AI, and Azure Foundry, see the [Provider Selection table in Amazon Bedrock Fundamentals](../bedrock-fundamentals/#provider-comparison).

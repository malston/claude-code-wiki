# External Integrations

## Overview

Claude Code Wiki integrates with minimal external services. The primary integration is GitHub for version control and CI/CD deployment. There are no databases, no authentication providers, and no third-party APIs for core functionality.

## GitHub Integration

### Repository Hosting

- **Repository:** `https://github.com/malston/claude-code-wiki`
- **Hosting:** GitHub (public repository)
- **Branch Strategy:** Single main branch for documentation
- **Submodule:** Hugo Book theme via git submodule
  - URL: `https://github.com/alex-shpak/hugo-book`
  - Path: `themes/hugo-book`
  - Fetch strategy: Recursive checkout with full history

### GitHub Actions Workflows

#### 1. Hugo Build & Deploy Pipeline

**Workflow File:** `/Users/markalston/code/claude-code-wiki/.github/workflows/hugo.yml`

**Triggers:**

- Push to `main` branch
- Manual workflow dispatch via GitHub UI

**Integration Points:**

- **Action: actions/checkout@v4**
  - Clones repository with all submodules (recursive)
  - Fetches full history (`fetch-depth: 0`)
  - Needed for submodule theme resolution

- **Action: actions/configure-pages@v5**
  - Configures GitHub Pages environment
  - Outputs base URL for site deployment
  - Required for GitHub Pages deployment

- **Action: actions/upload-pages-artifact@v3**
  - Uploads built `public/` directory as artifact
  - Artifact retention: GitHub Actions default (90 days)
  - Artifact name: `github-pages`

- **Action: actions/deploy-pages@v4**
  - Deploys artifact to GitHub Pages
  - Automatically publishes to `https://malston.github.io/claude-code-wiki/`
  - Creates deployment record in repository

**Environment Variables (CI Context):**

- `HUGO_ENVIRONMENT`: Set to `production` for minified output
- `HUGO_CACHEDIR`: Uses runner temp directory
- `TZ`: America/Denver (for consistent timestamp generation)

**Artifacts Generated:**

- Search index: `en.search-data.min.<hash>.json`
- Minified CSS/JS bundles
- HTML pages with optimizations (`--gc --minify` flags)

#### 2. Style Check on Pull Requests

**Workflow File:** `/Users/markalston/code/claude-code-wiki/.github/workflows/style-check.yml`

**Triggers:**

- Pull requests with changes to `content/**/*.md`

**Integration Points:**

- **Action: actions/checkout@v4**
  - Clones repository with full history
  - Enables git diff against base branch

**Environment Variables (CI Context):**

- `GITHUB_BASE_REF`: Automatically set to pull request base branch (typically `main`)
- Used by `scripts/check-style.sh` to detect changed files

**Exit Behavior:**

- Exit code 0: All checks pass (PR can merge)
- Exit code 1: Style violations found (PR blocked)

#### 3. Claude Code Review on Pull Requests

**Workflow File:** `/Users/markalston/code/claude-code-wiki/.github/workflows/claude-code-review.yml`

**Triggers:**

- Pull requests (opened, synchronize, ready_for_review, reopened)

**Integration Points:**

- **Action: anthropics/claude-code-action@v1**
  - Third-party action maintained by Anthropic
  - Executes Claude Code for automated code review
  - Can post review comments to PR

**Authentication:**

- **Secret: CLAUDE_CODE_OAUTH_TOKEN**
  - GitHub repository secret (encrypted)
  - Stored in `.github/secrets/`
  - Required for Claude Code authentication
  - Provides access to Anthropic API

**Plugin Configuration:**

- **Plugin Marketplace:** `https://github.com/anthropics/claude-code.git`
- **Plugin Used:** `code-review@claude-code-plugins`
  - Executed as: `/code-review:code-review ${{ github.repository }}/pull/${{ github.event.pull_request.number }}`
  - Reviews PR diff and posts findings

**Permissions Granted to Action:**

- `contents:read`: Read repository contents
- `pull-requests:read`: Read PR details
- `issues:read`: Read issue context
- `id-token:write`: Generate OIDC token for authentication

### GitHub Pages Deployment

- **Hosting Service:** GitHub Pages
- **Public URL:** `https://malston.github.io/claude-code-wiki/`
- **Base URL (Hugo Config):** `https://malston.github.io/claude-code-wiki/`
- **Build Output:** Uploaded from `public/` directory
- **Deployment Method:** GitHub Actions via `actions/deploy-pages@v4`
- **SSL/TLS:** Automatic (GitHub managed certificates)
- **Custom Domain:** None (uses GitHub domain)

## Third-Party Services

### Font CDN - Google Fonts

**Endpoint:** `https://fonts.googleapis.com/css2`

**Fonts Loaded:**

- Crimson Pro (serif, display font)
- Inter (sans-serif, body font)
- JetBrains Mono (monospace, code font)

**Implementation:** CSS `@import` in `/Users/markalston/code/claude-code-wiki/static/css/custom.css` (line 6)

**Usage:**

- Display headings: Crimson Pro 400, 600, 700 weights
- Body text: Inter 400, 500, 600 weights
- Code blocks: JetBrains Mono 400, 500 weights

**Fallback Strategy:** Web fonts are progressive enhancement; system fonts used if CDN unavailable

### Anthropic API - Claude Code Action

**Service:** Anthropic Claude API (via GitHub Actions)

**Configuration:**

- **Endpoint:** Handled by `anthropics/claude-code-action@v1`
- **Authentication:** OAuth token via `CLAUDE_CODE_OAUTH_TOKEN`
- **Usage:** Automated PR code review

**Request Scope:**

- PR diff content
- Repository context
- Pull request metadata

**Rate Limiting:** Managed by GitHub Actions and Anthropic API quotas

**Cost Model:** Billed through Anthropic API account

## Data Flows

### Content to Published Site

```
content/ (Markdown)
    ↓
Hugo (Static Generator)
    ↓
public/ (HTML, CSS, JS)
    ↓
GitHub Pages
    ↓
https://malston.github.io/claude-code-wiki/
```

### Pull Request Review Flow

```
Pull Request
    ↓
GitHub Actions Trigger (claude-code-review.yml)
    ↓
anthropics/claude-code-action@v1
    ↓
Anthropic Claude API
    ↓
Review Comments Posted to PR
```

### Style Check Flow

```
Pull Request (content changes)
    ↓
GitHub Actions Trigger (style-check.yml)
    ↓
bash scripts/check-style.sh
    ↓
git diff (against base branch)
    ↓
Regex Validation (local execution)
    ↓
Pass/Fail Status on PR
```

## Authentication & Secrets

### GitHub Secrets (Repository Level)

**Secret: CLAUDE_CODE_OAUTH_TOKEN**

- **Scope:** GitHub repository secrets
- **Used By:** `.github/workflows/claude-code-review.yml`
- **Type:** OAuth token (Anthropic)
- **Encryption:** AES-256 (GitHub managed)
- **Rotation Policy:** Manual (no automation)
- **Visibility:** Hidden from workflow logs

### OAuth Token Flow

1. GitHub Action requests OAuth token from secret
2. Token passed to `anthropics/claude-code-action@v1`
3. Action authenticates with Anthropic API
4. Token never logged or exposed in workflow output

## External API Integrations

### None for Core Functionality

- No database APIs
- No authentication providers (OAuth, SAML)
- No payment processors
- No analytics APIs (no GA, Segment, etc.)
- No monitoring services (no Sentry, NewRelic)
- No CDN services (GitHub Pages serves all content)
- No CMS APIs

### Optional Integrations (Not Currently Enabled)

The Hugo Book theme supports:

- Disqus comments (not enabled in current config)
- Search backend (using client-side only)
- Multilingual content (configured for en-us only)

## Security Considerations

### No Sensitive Data at Rest

- No user database
- No session tokens stored in repository
- No API keys in version control
- `CLAUDE_CODE_OAUTH_TOKEN` encrypted by GitHub

### Supply Chain Security

- **Theme Submodule:** Pinned to specific commit in `.gitmodules`
- **Binary Verification:** Hugo binary SHA256 verified in CI workflow
- **Dependency Lockdown:** No npm/package manager dependencies

### Network Security

- HTTPS enforced by GitHub Pages (automatic)
- Google Fonts loaded over HTTPS
- No local API endpoints exposed
- Static content only (no server-side code execution)

## Deployment Pipeline Security

### Permissions Model

**GitHub Actions Permissions (minimal):**

- `contents:read`: Read repository
- `pages:write`: Deploy to GitHub Pages
- `id-token:write`: Generate OIDC token for Pages
- Claude Code Review action: `id-token:write` for Anthropic auth

### No Secrets Exposed

- Build logs do not contain secrets
- `CLAUDE_CODE_OAUTH_TOKEN` masked in workflow output
- No credentials passed to shell environment
- Theme submodule fetched via public URL

## Webhook Configuration

### GitHub Webhooks (Automatic)

GitHub Pages configuration automatically creates webhooks for:

- Push events to `main` branch
- Workflow run completion

No custom webhooks configured.

## Integration Failure Modes

| Integration         | Failure Mode       | Impact                                | Mitigation                                   |
| ------------------- | ------------------ | ------------------------------------- | -------------------------------------------- |
| Google Fonts CDN    | Unavailable        | Typography falls back to system fonts | System fonts specified as fallback           |
| GitHub Pages Deploy | Fails              | Site not published                    | Workflow shows failed status on PR           |
| Claude Code Review  | API unavailable    | Review skipped                        | PR still mergeable, manual review required   |
| Hugo Book Theme     | Submodule missing  | Build fails                           | Local `git submodule update --init` required |
| GitHub Actions      | Runner unavailable | Build delayed                         | Queued until runner available                |

## Integration Statistics

| Component            | Status | Type            | Criticality |
| -------------------- | ------ | --------------- | ----------- |
| GitHub Repository    | Live   | Version Control | Critical    |
| GitHub Pages         | Live   | Hosting         | Critical    |
| GitHub Actions       | Live   | CI/CD           | Critical    |
| Google Fonts         | Live   | CDN             | Optional    |
| Anthropic Claude API | Live   | PR Review       | Optional    |
| Hugo Book Theme      | Live   | Submodule       | Critical    |

## Planned Integrations

- None documented in current repository

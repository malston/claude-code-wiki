# Claude Code Wiki - Architecture

## System Overview

Claude Code Wiki is a **static site documentation platform** built on Hugo (static site generator) with the Book theme. It serves as a comprehensive knowledge base for Claude Code internals, usage patterns, and enterprise deployment guidance.

**Purpose**: Multi-audience educational resource covering internals, guides, extensibility, and enterprise architecture.

**Deployment**: GitHub Pages (automated via GitHub Actions) to `https://malston.github.io/claude-code-wiki/`

**Technology Stack**:

- Hugo (static site generator)
- Hugo Book theme (sidebar navigation, responsive layout)
- Markdown (content authoring)
- GitHub Actions (CI/CD)
- Bash (scripting and style validation)

## Architectural Patterns

### 1. Content-Driven Architecture

The entire site is **content-first**, organized around knowledge domains rather than technical implementation:

```
Input Layer (Content)
    ↓
Processing Layer (Hugo, Markdown, Style Checks)
    ↓
Output Layer (Static HTML → GitHub Pages)
```

Content is the source of truth. Hugo renders markdown to HTML at build time. No dynamic server-side logic or databases.

### 2. Hierarchical Section Model

Content is organized into **6 major sections**, each with semantic scope:

1. **Internals** (1,992 LOC) -- How Claude Code works technically
   - System prompt anatomy, context mechanics, caching, token optimization, extended thinking

2. **Guides** (5,663 LOC) -- How to use Claude Code effectively
   - Prompting strategies, workflows, debugging, testing, model selection, memory, permissions

3. **Extending** (5,054 LOC) -- How to build on Claude Code
   - Subagents, skills, hooks, MCP servers, integration patterns, agent teams

4. **Enterprise Rollout** (3,560 LOC) -- 12-week deployment guide for 500-developer organizations
   - Infrastructure, platform engineering, phased rollout, governance, cost tracking

5. **Perspectives** (744 LOC) -- Opinion content on AI-assisted development
   - High-level thoughts on disruption, hype, programmer displacement, structured development

6. **Training** (909 LOC) -- Role-based learning paths
   - Structured curriculum for developers, platform engineers, product managers

Each section has an `_index.md` file that serves as the section landing page.

### 3. Single Source of Truth (Content/)

All **publishable content** lives in `content/` directory. No content duplication across branches or versions.

```
content/
  _index.md                      (site root/homepage)
  internals/
    _index.md                    (section landing)
    system-prompt.md
    context-management.md
    prompt-caching.md
    token-optimization.md
    extended-thinking.md
    tool-execution-context.md
  guides/
    _index.md
    effective-prompting.md
    workflow-patterns.md
    ... (11 articles)
  extending/
    _index.md
    extension-mechanisms.md
    custom-extensions.md
    ... (5 articles)
  enterprise-rollout/
    _index.md
    00-overview/
      _index.md
      executive-summary.md
      architecture-overview.md
    01-skill-gaps-and-market-opportunity/
      _index.md
      skill-gaps.md
      market-opportunity.md
    02-phase-0-infrastructure-foundation/
      _index.md
      bedrock-fundamentals.md
      vpc-privatelink.md
      llm-gateway.md
      ... (5 articles)
    ... (more phase directories)
    appendix/
      _index.md
      build-out-timeline.md
      reference-configs.md
  perspectives/
    _index.md
    structured-ai-development.md
    ai-disruption-speed-problem.md
    ... (5 articles)
  training/
    _index.md
    developer-path.md
    platform-engineer-path.md
    product-manager-path.md
```

**Key constraint**: `ignoreFiles = ['CLAUDE\.md$']` in `hugo.toml` prevents Claude Code memory files from being published to the site.

### 4. Theme-Based Rendering

Hugo **Book theme** provides:

- **Automatic sidebar navigation** (configured with `BookSection = '*'` to show all sections)
- **Responsive layout** (single-column on mobile, multi-column on desktop)
- **Table of contents** (configured to show levels 2-4 only)
- **Search functionality** (client-side)
- **Syntax highlighting** (Monokai style, no line numbers)

Custom overrides live in:

- `layouts/partials/docs/inject/head.html` -- Injects custom CSS
- `static/css/custom.css` -- Custom styling (17KB)

### 5. Build Pipeline

```
Source (content/*.md)
    ↓
Hugo Markdown Parser (Goldmark with unsafe HTML enabled)
    ↓
Theme Rendering (Hugo Book theme layouts)
    ↓
Static Output (public/ directory)
    ↓
Artifact Upload
    ↓
GitHub Pages Deployment
```

**Configuration** in `hugo.toml`:

- Base URL: `https://malston.github.io/claude-code-wiki/`
- Language: English (US)
- Theme: hugo-book
- Markup: Goldmark renderer with `unsafe = true` (allows HTML in markdown)
- Syntax highlighting: Monokai, no line numbers

### 6. Style Validation Pipeline

**Mechanical enforcement** via `scripts/check-style.sh`:

```
Content File
    ↓
Check 1: Em dashes (— → --)
Check 2: Bare code fences (requires language specifier)
Check 3: Banned opener phrases ("Let's be honest", "Here's the thing", etc.)
Check 4: Contrastive reframes ("It's not X, it's Y")
Check 5: Superlative filler (powerful, seamless, elegant, robust)
Check 6: Triplet lists (three items for rhythm, not substance)
Check 7: Relative timeline phrasing (new, recently, improved, legacy)
Check 8: Internal implementation names (private classes, struct names)
    ↓
Pass/Fail with line-by-line violations
```

This runs in GitHub Actions CI. Exempt files are listed in the script (currently just the Dario transcript).

### 7. CI/CD Pipeline

Three GitHub Actions workflows:

1. **hugo.yml** -- Builds and deploys site
   - Downloads Hugo 0.155.2 with SHA256 verification
   - Checks out with recursive submodules (for theme)
   - Runs production build with `hugo --gc --minify`
   - Uploads to GitHub Pages artifact
   - Deploys via `actions/deploy-pages@v4`

2. **style-check.yml** -- Enforces mechanical style rules
   - Runs `bash scripts/check-style.sh content/`
   - Fails build if violations found

3. **claude-code-review.yml** -- AI-assisted code review
   - Triggered on PR changes
   - Invokes Claude for subjective style feedback

### 8. Project Metadata System (Conductor)

`conductor/` directory contains **project coordination metadata**:

```
conductor/
  product.md                 (product vision/definition)
  product-guidelines.md      (brand and messaging guidelines)
  tech-stack.md             (tools and dependencies)
  workflow.md               (development workflow)
  tracks.md                 (feature tracking methodology)
  index.md                  (navigation hub)
  setup_state.json          (project setup status)
  code_styleguides/
    markdown.md
    shell.md
  tracks/
    training-section_20260220/
      metadata.json
      index.md
      spec.md
      plan.md
    exercise-materials_20260220/
      metadata.json
      index.md
      spec.md
      plan.md
    exercise-solutions_20260220/
      metadata.json
      index.md
      spec.md
      plan.md
```

**Not published** to the site (metadata only, lives in `.planning/` during build).

## Data Flow

### Content Creation Flow

```
Writer creates markdown file
    ↓
Commit to feature branch
    ↓
GitHub Actions: style-check.yml runs check-style.sh
    ↓
GitHub Actions: claude-code-review.yml runs AI review
    ↓
Pull request with automated feedback
    ↓
Writer addresses feedback
    ↓
Approval and merge to main
    ↓
GitHub Actions: hugo.yml builds and deploys
    ↓
Live on GitHub Pages
```

### Site Rendering Flow

```
hugo.toml (configuration)
    ↓
Content files (markdown in content/)
    ↓
Hugo template rendering (layouts/)
    ↓
Theme partials (themes/hugo-book/layouts/)
    ↓
Custom CSS injection (layouts/partials/docs/inject/head.html)
    ↓
Static HTML output (public/)
    ↓
Site index and search index generation
    ↓
Artifact upload to GitHub Pages
```

## Entry Points

### For Readers

- **Root URL**: `https://malston.github.io/claude-code-wiki/`
- **By section**: `/internals/`, `/guides/`, `/extending/`, `/enterprise-rollout/`, `/perspectives/`, `/training/`
- **By article**: `/internals/context-management/`, `/guides/effective-prompting/`, etc.
- **Search**: Built-in client-side search from Hugo Book theme

### For Contributors

- **Local development**: `hugo serve` (watches for changes, live reload)
- **Production build**: `hugo` or `hugo --gc --minify`
- **Style validation**: `bash scripts/check-style.sh content/`
- **Makefile**: `make server`, `make build`, `make clean`, `make lint`

### For CI/CD

- **Style checks**: Triggered on PR, blocks merge if violations
- **Hugo build**: Triggered on push to main, runs production build
- **Deployment**: Automatic to GitHub Pages after successful build

## Abstractions

### Hugo Front Matter

Each markdown file has YAML front matter defining metadata:

```yaml
---
title: "Article Title"
weight: 10
---
```

**Title** appears in navigation and browser tab. **Weight** controls sidebar ordering (higher = later in list).

### Section Organization

Each section (`internals/`, `guides/`, etc.) is an independent Hugo section. Hugo automatically:

- Discovers all `.md` files in the section
- Renders them as pages
- Builds sidebar navigation from section structure
- Generates section landing page from `_index.md`

### Theme Customization

Hugo Book theme is minimally customized:

- Uses `layouts/partials/docs/inject/head.html` to inject `custom.css`
- No layout overrides (uses theme defaults)
- Configuration via `hugo.toml` params

### Markdown Processing

Goldmark markdown parser with:

- Unsafe HTML enabled (allows inline `<div>` and `<style>` tags)
- Syntax highlighting configured but line numbers disabled
- Table of contents generation (levels 2-4 only)

## Key Technical Decisions

1. **Static site over dynamic** -- Content doesn't change mid-session; static output is performant and reliable
2. **Single repo, single source of truth** -- No content versioning or branching; main branch is always published
3. **Mechanical + subjective style checks** -- CI handles deterministic rules; humans handle judgment calls
4. **Hugo for simplicity** -- Minimal setup, theme ecosystem, built-in features (search, TOC, sidebar nav)
5. **Section-based organization** -- Mirrors audience/topic structure; easier navigation than flat article list
6. **Conductor for project metadata** -- Separates coordination info (conductor/) from published content (content/)
7. **No backend** -- Pure GitHub Pages hosting, no servers to maintain
8. **Safe markdown rendering** -- `unsafe = true` allows HTML but CLAUDE.md files are excluded from build

## Build Artifacts

**Generated at build time**:

- `public/` -- Complete static site (HTML, CSS, JS, search index)
- `resources/` -- Hugo resource cache (images, processed assets)

**Ignored in git** (.gitignore):

- `public/`
- `resources/`
- `.claude/settings.local.json`
- `.claude/conversation-*`
- Secrets and keys
- OS files

## Scaling Considerations

**Current state**: 84 markdown files, ~18,500 total lines of content, 6 major sections

**If section grows**:

- Add new subdirectories under section parent
- Each directory gets `_index.md` as landing page
- Hugo auto-discovers and renders
- Sidebar navigation updates automatically

**If site grows to multiple teams**:

- Consider branching per team (one repo per audience)
- Current single-repo model assumes unified editorial control
- Conductor metadata could expand to track ownership/approval workflows

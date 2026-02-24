# Claude Code Wiki - Directory Structure

## Root Directory Layout

```
/Users/markalston/code/claude-code-wiki/
├── .claude/                    # Claude Code local context (excluded from git)
│   └── CLAUDE.md              # Project-level memory/notes (ignored in .gitignore)
├── .github/
│   └── workflows/             # GitHub Actions CI/CD pipelines
│       ├── hugo.yml           # Build and deploy to GitHub Pages
│       ├── style-check.yml    # Mechanical style validation
│       └── claude-code-review.yml # AI-assisted review
├── .planning/
│   └── codebase/              # This analysis output
├── .gitignore                 # Git ignore rules
├── .gitmodules                # Git submodule configuration (hugo-book)
├── CLAUDE.md                  # Project instructions (checked in)
├── Makefile                   # Development convenience commands
├── README.md                  # Public repository description
├── hugo.toml                  # Hugo site configuration
├── content/                   # Published content (single source of truth)
├── layouts/                   # Hugo template overrides
├── static/                    # Static assets (CSS, images)
├── themes/                    # Hugo themes (git submodule)
├── resources/                 # Hugo cache (generated, .gitignored)
├── public/                    # Built site output (generated, .gitignored)
├── conductor/                 # Project coordination metadata
└── scripts/                   # Utility shell scripts
```

## Content Directory (Published Material)

The `content/` directory is the single source of truth for all published content. It follows Hugo's section-based organization.

```
content/
├── _index.md                  # Site homepage/root
│
├── internals/                 # How Claude Code works internally (1,992 LOC total)
│   ├── _index.md             # Section landing page
│   ├── CLAUDE.md             # Section notes (not published)
│   ├── system-prompt.md      # System prompt anatomy and components
│   ├── context-management.md # Context window mechanics and compaction
│   ├── prompt-caching.md     # Prompt caching cost and mechanics
│   ├── token-optimization.md # Token auditing and optimization
│   ├── extended-thinking.md  # Extended reasoning and thinking tokens
│   └── tool-execution-context.md # Tool execution environment
│
├── guides/                    # How to use Claude Code effectively (5,663 LOC total)
│   ├── _index.md
│   ├── CLAUDE.md
│   ├── effective-prompting.md
│   ├── workflow-patterns.md
│   ├── debugging-techniques.md
│   ├── testing-strategies.md
│   ├── model-selection.md
│   ├── memory-organization.md
│   ├── permissions-enterprise.md
│   ├── coding-assistants-context.md
│   ├── spec-driven-development.md
│   └── essential-plugins.md
│
├── extending/                 # How to build on Claude Code (5,054 LOC total)
│   ├── _index.md
│   ├── CLAUDE.md
│   ├── extension-mechanisms.md
│   ├── custom-extensions.md
│   ├── hooks-cookbook.md
│   ├── integration-patterns.md
│   └── agent-teams.md
│
├── enterprise-rollout/        # 12-week deployment guide (3,560 LOC total)
│   ├── _index.md
│   ├── CLAUDE.md
│   │
│   ├── 00-overview/           # Phase overview and executive summary
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── executive-summary.md
│   │   └── architecture-overview.md
│   │
│   ├── 01-skill-gaps-and-market-opportunity/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── skill-gaps.md
│   │   └── market-opportunity.md
│   │
│   ├── 02-phase-0-infrastructure-foundation/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── bedrock-fundamentals.md
│   │   ├── vpc-privatelink.md
│   │   ├── llm-gateway.md
│   │   ├── security-constraint-clarification.md
│   │   ├── vertex-fundamentals.md
│   │   └── foundry-fundamentals.md
│   │
│   ├── 03-phase-1-platform-engineering/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── managed-settings.md
│   │   ├── developer-environment.md
│   │   ├── claude-md-architecture.md
│   │   ├── skills-commands-rules-decision-framework.md
│   │   ├── skills-library-design.md
│   │   ├── context-budget-worksheet.md
│   │   └── failure-modes.md
│   │
│   ├── 04-phase-2-phased-rollout/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   └── cohort-strategy.md
│   │
│   ├── 05-phase-3-observability-and-governance/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── audit-compliance.md
│   │   ├── cost-tracking.md
│   │   └── security-controls.md
│   │
│   ├── 06-implementation-support-ecosystem/
│   │   ├── _index.md
│   │   ├── CLAUDE.md
│   │   ├── support-landscape.md
│   │   └── pushback-recommendations.md
│   │
│   └── appendix/
│       ├── _index.md
│       ├── CLAUDE.md
│       ├── build-out-timeline.md
│       ├── cf-analogy-map.md
│       └── reference-configs.md
│
├── perspectives/              # Opinion content on AI development (744 LOC total)
│   ├── _index.md
│   ├── CLAUDE.md
│   ├── structured-ai-development.md
│   ├── ai-disruption-speed-problem.md
│   ├── ai-replacing-programmers.md
│   └── 2026-02-12-dario-we-dont-know-ai-conscious.md
│
└── training/                  # Role-based learning paths (909 LOC total)
    ├── _index.md
    ├── CLAUDE.md
    ├── developer-path.md      # Curriculum for software developers
    ├── platform-engineer-path.md # Curriculum for platform/DevOps engineers
    └── product-manager-path.md # Curriculum for product managers
```

### Naming Conventions

**Section directories**: Lowercase, hyphenated

- `internals/`, `guides/`, `extending/`, `enterprise-rollout/`

**Content files**: Lowercase, hyphenated, `.md` extension

- `effective-prompting.md`, `system-prompt.md`, `vpc-privatelink.md`

**Index files**: `_index.md` (Hugo convention for section landing pages)

**Local notes**: `CLAUDE.md` (excluded from build via `.gitignore`)

**Subsections** (enterprise-rollout): Numbered prefixes for ordering

- `00-overview/`, `01-skill-gaps-and-market-opportunity/`, etc.

## Layouts Directory (Theme Customization)

Hugo template overrides and injections.

```
layouts/
├── CLAUDE.md                  # Local notes (not published)
└── partials/
    └── docs/
        ├── CLAUDE.md
        └── inject/
            ├── CLAUDE.md
            └── head.html      # Injects custom CSS into <head>
```

**Purpose**: Minimal customization of Hugo Book theme.

`head.html` includes:

```html
<link rel="stylesheet" href="{{ "css/custom.css" | relURL }}">
```

This allows custom CSS to override theme styles without modifying theme files directly.

## Static Directory (Assets)

```
static/
├── CLAUDE.md                  # Local notes (not published)
└── css/
    ├── CLAUDE.md
    └── custom.css            # Custom stylesheet (17KB)
```

`custom.css` provides:

- Custom typography rules
- Color overrides
- Layout adjustments
- Code block styling

Sourced by `layouts/partials/docs/inject/head.html`.

## Themes Directory (Hugo Book Submodule)

Hugo Book theme is installed as a git submodule.

```
themes/
└── hugo-book/                # Git submodule (not part of this repo)
    ├── layouts/              # Theme templates (HTML/Go)
    ├── assets/               # Theme assets (CSS, JS)
    ├── static/               # Theme static files
    ├── i18n/                 # Internationalization files
    ├── archetypes/           # Markdown scaffolds for new content
    └── exampleSite/          # Example site configuration
```

Checked out at `themes/hugo-book/.git` (git submodule pointer file).

**Commit**: Latest available version as of Feb 9, 2026 (~v0.155)

**How to update**:

```bash
cd themes/hugo-book
git fetch origin
git checkout origin/main  # or specific commit
cd ../..
git add themes/hugo-book
git commit -m "chore: update hugo-book theme"
```

## Scripts Directory (Utilities)

```
scripts/
├── CLAUDE.md                  # Local notes (not published)
└── check-style.sh            # Style validation script (6.6KB)
```

### check-style.sh

Mechanical style checks that run in CI and locally before commit.

**Usage**:

```bash
bash scripts/check-style.sh [file-or-dir ...]
bash scripts/check-style.sh content/guides/effective-prompting.md
bash scripts/check-style.sh content/
```

**Checks performed**:

1. Em dash characters (— → --)
2. Bare code fences (must have language specifier)
3. Banned opener phrases ("Let's be honest", "Here's the thing", "The truth is")
4. Contrastive reframes ("It's not X, it's Y")
5. Superlative filler (powerful, seamless, elegant, robust, cutting-edge, game-changing)
6. Triplet lists (three items used for rhythm, not substance)
7. Relative timeline phrasing (new, recently, improved, legacy)
8. Internal implementation names (private class names, struct names)

**Exempt files** (hardcoded in script):

- `2026-02-12-dario-we-dont-know-ai-conscious.md` (external transcript)

**Exit codes**:

- `0` if clean
- `1` if violations found (CI blocks merge)

## Conductor Directory (Project Metadata)

Hugo-agnostic project coordination and tracking metadata. **Not published** to the site.

```
conductor/
├── index.md                   # Navigation hub for project context
├── product.md                 # Product vision and definition
├── product-guidelines.md      # Brand, messaging, positioning guidelines
├── tech-stack.md             # Tools, dependencies, versions
├── workflow.md               # Development workflow and process
├── tracks.md                 # Feature tracking methodology
├── setup_state.json          # Project setup completion state
├── CLAUDE.md                 # Project notes
│
├── code_styleguides/         # Code style guides (not markdown content)
│   ├── CLAUDE.md
│   ├── markdown.md           # Markdown writing standards
│   └── shell.md              # Bash scripting standards
│
└── tracks/                   # Feature/content work tracking
    ├── CLAUDE.md
    │
    ├── training-section_20260220/     # Training content section
    │   ├── metadata.json              # Track metadata
    │   ├── index.md                   # Track overview
    │   ├── spec.md                    # Detailed specifications
    │   ├── plan.md                    # Implementation plan
    │   └── CLAUDE.md
    │
    ├── exercise-materials_20260220/   # Training exercise repos
    │   ├── metadata.json
    │   ├── index.md
    │   ├── spec.md
    │   ├── plan.md
    │   └── CLAUDE.md
    │
    └── exercise-solutions_20260220/   # Solution branches
        ├── metadata.json
        ├── index.md
        ├── spec.md
        ├── plan.md
        └── CLAUDE.md
```

**Purpose**: Separate operational/coordination metadata from published content. Conductor files are Hugo-agnostic and focus on project management rather than user-facing documentation.

**Track system**: Each major feature/content work has a dated track (e.g., `training-section_20260220`) with:

- `metadata.json` -- Track state (completed/in-progress/planning)
- `spec.md` -- Detailed requirements and acceptance criteria
- `plan.md` -- Step-by-step implementation plan
- `index.md` -- Overview and linking to other docs

## GitHub Actions Workflows (.github/workflows/)

```
.github/
└── workflows/
    ├── CLAUDE.md              # Local notes about workflows
    ├── hugo.yml               # Build and deploy to GitHub Pages
    ├── style-check.yml        # Run mechanical style validation
    └── claude-code-review.yml # Invoke Claude for AI review
```

### hugo.yml (Main Build/Deploy)

**Trigger**: Push to `main` branch or manual `workflow_dispatch`

**Steps**:

1. Install Hugo 0.155.2 (with SHA256 verification)
2. Checkout with recursive submodules (theme)
3. Build with `hugo --gc --minify`
4. Upload artifact to GitHub Pages
5. Deploy to `https://malston.github.io/claude-code-wiki/`

**Key environment variables**:

- `HUGO_VERSION=0.155.2`
- `HUGO_CACHEDIR=${{ runner.temp }}/hugo_cache`
- `HUGO_ENVIRONMENT=production`
- `TZ=America/Denver`

### style-check.yml (Mechanical Validation)

**Trigger**: PR with changes to `content/**/*.md`

**Steps**:

1. Run `bash scripts/check-style.sh content/`
2. Fail with exit code 1 if violations found
3. Block merge until resolved

### claude-code-review.yml (AI Review)

**Trigger**: PR with changes to `content/**/*.md`

**Purpose**: Invoke Claude for subjective style feedback (beyond mechanical checks)

## Configuration Files

### hugo.toml (Hugo Site Configuration)

```toml
baseURL = 'https://malston.github.io/claude-code-wiki/'
languageCode = 'en-us'
title = 'Claude Code Wiki'
theme = 'hugo-book'
ignoreFiles = ['CLAUDE\.md$']  # Exclude Claude Code memory files

[params]
  BookTheme = 'auto'           # Light/dark mode
  BookToC = true               # Show table of contents
  BookSection = '*'            # Show all sections in sidebar
  BookRepo = 'https://github.com/malston/claude-code-wiki'
  BookSearch = true            # Enable search

[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true            # Allow HTML in markdown
  [markup.highlight]
    style = 'monokai'
    lineNos = false            # No line numbers
    noClasses = false
  [markup.tableOfContents]
    startLevel = 2
    endLevel = 4
```

### .gitignore

```
# Claude Code local settings
.claude/settings.local.json
.claude/conversation-*
**/CLAUDE.md
!.claude/CLAUDE.md
!.github/workflows/CLAUDE.md
!/CLAUDE.md
.claude/*.local.md

# Secrets
**/secrets/
*.pem
*.key
!*.key.example
terraform/certs/generated/
.envrc

# Hugo
public/
resources/

# OS files
.DS_Store

# Editor
.idea/
*.swp
*.swo
```

**Strategy**: Ignore CLAUDE.md everywhere except at root and special locations. Hugo doesn't publish them due to `ignoreFiles` in config.

### .gitmodules

```
[submodule "themes/hugo-book"]
    path = themes/hugo-book
    url = https://github.com/alex-shpak/hugo-book.git
```

Manages theme as a git submodule (checked out separately).

### Makefile

```make
.PHONY: help server build clean lint

help:
    @echo 'Usage: make [target]'
    @awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / ...'

server: ## Start Hugo development server
    hugo server

build: ## Build static site to public/
    hugo

clean: ## Remove generated files
    rm -rf public/

lint: ## Run style checks
    bash scripts/check-style.sh content/
```

**Convenience targets** for local development.

## Generated/Ignored Directories

### public/ (Generated Site)

Output of Hugo build. Contains complete static site:

```
public/
├── index.html
├── css/
├── js/
├── internals/
│   ├── index.html
│   ├── system-prompt/
│   ├── context-management/
│   └── ...
├── guides/
│   ├── index.html
│   ├── effective-prompting/
│   └── ...
└── search.json              # Client-side search index
```

Rebuilt on every `hugo` command. Ignored in `.gitignore`.

### resources/ (Hugo Cache)

Hugo's internal asset cache:

```
resources/
└── _gen/
    ├── assets/              # Processed CSS, JS
    └── images/              # Responsive images
```

Ignored in `.gitignore`. Regenerated as needed.

## File Counts and Statistics

| Directory                     | Files                      | LOC         | Purpose                   |
| ----------------------------- | -------------------------- | ----------- | ------------------------- |
| `content/internals/`          | 7 (6 articles + \_index)   | 1,992       | How Claude Code works     |
| `content/guides/`             | 12 (11 articles + \_index) | 5,663       | How to use Claude Code    |
| `content/extending/`          | 6 (5 articles + \_index)   | 5,054       | How to extend Claude Code |
| `content/enterprise-rollout/` | 25                         | 3,560       | 12-week deployment guide  |
| `content/perspectives/`       | 6 (5 articles + \_index)   | 744         | Opinion pieces            |
| `content/training/`           | 4 (3 paths + \_index)      | 909         | Learning paths            |
| **Total content**             | **84**                     | **~18,500** |                           |
| `layouts/`                    | 1                          | 63          | CSS injection             |
| `static/css/`                 | 1                          | 17KB        | Custom styling            |
| `scripts/`                    | 1                          | 6.6KB       | Style validation          |
| `.github/workflows/`          | 3                          | ~5KB        | CI/CD pipelines           |

## Key Design Principles

1. **Content-first** -- All paths lead back to `content/` as the source of truth
2. **Hugo conventions** -- Uses standard Hugo structure (`content/`, `layouts/`, `static/`)
3. **Minimal customization** -- Only overrides theme where necessary
4. **Metadata separation** -- `conductor/` keeps coordination info separate from published content
5. **No secrets in repo** -- Secrets and local settings are .gitignored
6. **CLAUDE.md excluded** -- All local notes excluded from published site automatically
7. **Style-as-code** -- Mechanical checks in git hooks and CI prevent style violations

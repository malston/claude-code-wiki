# Technology Stack

## Overview

Claude Code Wiki is a static documentation site built with Hugo and deployed to GitHub Pages. The stack is minimal and focused on content delivery with no server-side runtime.

## Core Framework

| Component | Version   | Purpose                         |
| --------- | --------- | ------------------------------- |
| **Hugo**  | 0.155.2   | Static site generator           |
| **Theme** | hugo-book | Documentation theme (submodule) |
| **Go**    | 1.16+     | Hugo runtime requirement        |

## Configuration Files

### `hugo.toml`

- **Location:** `/Users/markalston/code/claude-code-wiki/hugo.toml`
- **Key Settings:**
  - Base URL: `https://malston.github.io/claude-code-wiki/`
  - Language: `en-us`
  - Theme: `hugo-book` (git submodule)
  - Ignored files: `CLAUDE\.md$` (local development notes)
  - Goldmark renderer unsafe mode enabled (needed for HTML content)
  - Monokai syntax highlighting style
  - Search enabled
  - Table of contents: headers h2-h4
  - Date format: `January 2, 2006`

### `theme.toml` (Hugo Book Theme)

- **Location:** `/Users/markalston/code/claude-code-wiki/themes/hugo-book/theme.toml`
- **Theme Metadata:**
  - Name: Book
  - License: MIT
  - Author: Alex Shpak
  - Minimum Hugo version: 0.146.0
  - Repository: https://github.com/alex-shpak/hugo-book
  - Features: responsive, clean, documentation, search, mobile, multilingual

### `.gitmodules`

- **Location:** `/Users/markalston/code/claude-code-wiki/.gitmodules`
- **Submodule:**
  - Path: `themes/hugo-book`
  - URL: `https://github.com/alex-shpak/hugo-book`

## Frontend Stack

### CSS

- **Custom CSS:** `/Users/markalston/code/claude-code-wiki/static/css/custom.css`
- **Typography:**
  - Display font: Crimson Pro (serif, Google Fonts)
  - Body font: Inter (sans-serif, Google Fonts)
  - Code font: JetBrains Mono (monospace, Google Fonts)
- **Theme System:**
  - Light theme (default): cream (#fdfbf7) and charcoal (#1a1512)
  - Dark theme: dark brown and light cream
  - CSS custom properties (variables) for all design tokens
  - Color palette: accent orange (#d97706), complementary grays
- **Responsive Design:**
  - Mobile-first approach
  - Breakpoints: 1200px, 992px, 768px
  - Sidebar width: 280px (desktop), 250px (medium)
  - Table of contents: 350px width (desktop, hidden on tablet/mobile)
  - Container max-width: 95vw
  - Content max-width: 85 characters
- **Features:**
  - Smooth scrolling
  - Fade-in animations (accessibility-aware)
  - Box shadows and gradients
  - Striped tables
  - Syntax highlighting for code blocks
  - Print styles
  - Reduced-motion media query support

### JavaScript

- No custom JavaScript; all interactivity via Hugo Book theme defaults
- Client-side search functionality (provided by theme)

### HTML

- **Custom Layout Injection:** `/Users/markalston/code/claude-code-wiki/layouts/partials/docs/inject/head.html`
  - Injects custom CSS link: `css/custom.css`

## Build & Deployment

### Makefile

- **Location:** `/Users/markalston/code/claude-code-wiki/Makefile`
- **Targets:**
  - `make server`: Start Hugo dev server with live reload
  - `make build`: Build static site to `public/` directory
  - `make clean`: Remove generated files
  - `make lint`: Run style checks on content

### GitHub Actions Workflows

#### Hugo Build & Deploy

- **Location:** `/Users/markalston/code/claude-code-wiki/.github/workflows/hugo.yml`
- **Trigger:** Push to main branch or manual workflow dispatch
- **Steps:**
  1. Install Hugo CLI 0.155.2 (Ubuntu Linux amd64)
  2. SHA256 verification of Hugo binary (security measure)
  3. Checkout repository with submodules (recursive) and full history
  4. Setup GitHub Pages environment
  5. Build with Hugo:
     - Garbage collection enabled (`--gc`)
     - Minification enabled (`--minify`)
     - Production environment variables
     - Timezone: America/Denver
     - Cache directory: runner temp
  6. Upload artifact to GitHub Pages
  7. Deploy via `actions/deploy-pages@v4`
- **Permissions:** contents:read, pages:write, id-token:write
- **Concurrency:** Cancel in-progress deployments for same group

#### Style Check

- **Location:** `/Users/markalston/code/claude-code-wiki/.github/workflows/style-check.yml`
- **Trigger:** Pull requests with content changes
- **Execution:** Runs `bash scripts/check-style.sh` on changed markdown files
- **Path Filter:** `content/**/*.md`

#### Claude Code Review

- **Location:** `/Users/markalston/code/claude-code-wiki/.github/workflows/claude-code-review.yml`
- **Trigger:** Pull requests (opened, synchronize, ready_for_review, reopened)
- **Action:** Uses `anthropics/claude-code-action@v1`
- **Configuration:**
  - OAuth token required (stored in GitHub secrets)
  - Plugin marketplace: https://github.com/anthropics/claude-code.git
  - Plugin: code-review@claude-code-plugins
  - Automatic PR review execution
- **Permissions:** contents:read, pull-requests:read, issues:read, id-token:write

### Build Artifacts

- **Output:** `/Users/markalston/code/claude-code-wiki/public/`
- **Deployment Target:** GitHub Pages (malston.github.io/claude-code-wiki)
- **Generated Assets:**
  - HTML pages
  - Minified CSS/JS (via Hugo)
  - Search index: `en.search-data.min.<hash>.json`

## Development Tools

### Bash Scripts

- **Location:** `/Users/markalston/code/claude-code-wiki/scripts/`
- **check-style.sh:** Mechanical style enforcement
  - Em dash detection and prevention
  - Bare code fence detection (requires language identifier)
  - Triple-hyphen em dash detection
  - Banned opener phrases: "let's be honest", "here's the thing", "the truth is", "at the end of the day", "let's be real"
  - Exempt files configuration
  - Supports CI mode (git diff against base branch) and manual file targets
  - Exit code: 0 (pass), 1 (violations found)

### CLI Tools

- `hugo` command (0.155.2)
  - `hugo server`: Development server with live reload
  - `hugo` or `hugo --gc --minify`: Production build
  - `hugo --version`: Check version

## Content Structure

### Source Files

- **Location:** `/Users/markalston/code/claude-code-wiki/content/`
- **Format:** Markdown (.md)
- **Ignored:** `CLAUDE.md` files (local development context)

### Static Assets

- **CSS:** `/Users/markalston/code/claude-code-wiki/static/css/`
- **Images:** Can be included in content, served from `static/`

### Layouts & Templates

- **Custom Overrides:** `/Users/markalston/code/claude-code-wiki/layouts/`
- **Theme Layouts:** `/Users/markalston/code/claude-code-wiki/themes/hugo-book/layouts/`

## Dependencies Summary

### External (NPM/Package Manager)

- **None** -- Hugo is self-contained binary, no npm packages

### Git Submodules

- `themes/hugo-book` (https://github.com/alex-shpak/hugo-book)
  - Contains all theme assets, layouts, and JavaScript

### CDN/External Resources

- **Google Fonts:** Crimson Pro, Inter, JetBrains Mono (loaded in CSS)
- **GitHub Actions:** Official actions (checkout, configure-pages, upload-pages-artifact, deploy-pages)

## Runtime Requirements

- **Local Development:** Hugo 0.146.0+ (binary installation)
- **CI/CD:** Ubuntu Linux, GitHub Actions runner
- **Deployment:** GitHub Pages (static hosting)
- **Client-Side:** Modern browser with JavaScript enabled (for search functionality)

## Environment Variables

### GitHub Actions (Build)

- `HUGO_VERSION`: 0.155.2 (pinned in workflow)
- `HUGO_CACHEDIR`: Temporary cache directory for build artifacts
- `HUGO_ENVIRONMENT`: `production`
- `TZ`: `America/Denver`

### Local Development

- `GITHUB_BASE_REF`: Used by style checker in CI mode (defaults to `main`)

## Configuration Inheritance

Hugo configuration hierarchy (processed in this order):

1. Theme defaults (hugo-book theme.toml)
2. Root `hugo.toml` (project overrides)
3. Environment-specific variables (HUGO_ENVIRONMENT=production)

## Notable Design Decisions

- **Static Generation Only:** No JavaScript build step, no Node.js dependency
- **Submodule Theme:** Hugo Book theme pinned at specific commit for reproducible builds
- **SHA256 Verification:** Binary verification in CI for security
- **Custom CSS:** Extends Hugo Book rather than modifying theme directly
- **Mechanical Linting:** Style checker uses regex for deterministic enforcement
- **Markdown-Only Content:** Single source of truth in `content/` directory

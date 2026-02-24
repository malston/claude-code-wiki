# Testing and Validation

## Overview

The Claude Code Wiki is a static site project with no application code to unit test. Validation focuses on:

1. **Style checking** - Automated linting of markdown content
2. **Build verification** - Hugo compilation to ensure site builds
3. **Deployment** - GitHub Actions automated deployment to GitHub Pages

There are no automated tests for logic, no test framework dependencies, and no test runner configuration.

---

## Testing Approach

This project uses a **static analysis** validation model rather than traditional unit testing. The goal is to ensure:

- Markdown follows style guidelines (no em dashes, code fences have language identifiers)
- Banned phrases don't appear in content
- Hugo successfully builds the site
- Deployment succeeds

---

## CI/CD Pipelines

### 1. Style Check (Pull Requests Only)

**Trigger**: `pull_request` event on paths matching `content/**/*.md`

**File**: `/Users/markalston/code/claude-code-wiki/.github/workflows/style-check.yml`

**Steps**:

```yaml
jobs:
  style-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run style checks
        env:
          GITHUB_BASE_REF: ${{ github.event.pull_request.base.ref }}
        run: bash scripts/check-style.sh
```

**Exit codes**:

- `0` - All checks pass (PR can merge)
- `1` - Violations found (PR blocked until fixed)

**When it runs**:

- Every pull request that modifies `content/**/*.md`
- Does not run on main branch pushes
- Skips `_index.md` and `CLAUDE.md` files

---

### 2. Build and Deploy (Main Branch)

**Trigger**: `push` to main branch or `workflow_dispatch` (manual)

**File**: `/Users/markalston/code/claude-code-wiki/.github/workflows/hugo.yml`

**Steps**:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.155.2
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb
          wget -O ${{ runner.temp }}/hugo_checksums.txt https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt
          cd ${{ runner.temp }}
          grep "hugo_extended_${HUGO_VERSION}_linux-amd64.deb" hugo_checksums.txt | sed "s/hugo_extended_${HUGO_VERSION}_linux-amd64.deb/hugo.deb/" > hugo.deb.sha256
          sha256sum -c hugo.deb.sha256
          sudo dpkg -i hugo.deb
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0
      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v5
      - name: Build with Hugo
        env:
          HUGO_CACHEDIR: ${{ runner.temp }}/hugo_cache
          HUGO_ENVIRONMENT: production
          TZ: America/Denver
        run: |
          hugo \
            --gc \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Build validation**:

- Downloads Hugo v0.155.2 and verifies SHA256 checksum
- Checks out repository with recursive submodule fetch
- Compiles site with `hugo --gc --minify`
- Build failure blocks deployment

**Deployment validation**:

- Uploads build artifact (`public/`) to GitHub Pages
- Only runs if build succeeds

---

### 3. Claude Code Integration (Optional)

**Trigger**: Issue/PR comments containing `@claude`, PR reviews with `@claude`

**File**: `/Users/markalston/code/claude-code-wiki/.github/workflows/claude.yml`

**Purpose**: Allows Claude Code CLI to review PRs and perform automated tasks

**Permissions**:

```yaml
permissions:
  contents: read
  pull-requests: read
  issues: read
  id-token: write
  actions: read
```

This is optional/supplementary automation -- not part of the core validation pipeline.

---

## Style Checking (Automated Linting)

### Script Location

`/Users/markalston/code/claude-code-wiki/scripts/check-style.sh`

### Execution

```bash
# Check all content files
bash scripts/check-style.sh content/

# Check specific files
bash scripts/check-style.sh /path/to/file.md

# CI mode (run from repo root, checks changed files)
bash scripts/check-style.sh
```

### Implementation Details

The script is a 212-line Bash script with four distinct checks:

#### 1. Em Dash Check: `check_em_dashes()`

**Lines**: 39-48

**Rule**: No em dash character (`—`)

**Pattern**: Line-by-line scan for `—` character

**Example violation**:

```
Bad:  "The bottleneck moved — it's shifted entirely."
Good: "The bottleneck moved -- it's shifted entirely."
```

#### 2. Triple Hyphen Em Dash Check: `check_triple_hyphen_em_dashes()`

**Lines**: 76-114

**Rule**: No triple-hyphen sequences (`---`) outside code blocks, tables, or YAML front matter

**Smart filtering**:

- Ignores lines entirely made of hyphens (horizontal rules)
- Ignores setext heading underlines
- Ignores pandoc table separators (`|---`)
- Strips inline code backticks before checking
- Skips content within code fences

**Example violation**:

```
Bad:  "This approach doesn't just work --- it scales."
Good: "This approach doesn't just work -- it scales."
```

#### 3. Bare Code Fence Check: `check_bare_code_fences()`

**Lines**: 50-73

**Rule**: All code fences must have a language identifier

**Pattern**: Opening fence (` ``` `) must have language after backticks

**Valid**:

```bash
code here
```

**Valid**:

```text
code here
```

**Invalid**:

```
code here
```

#### 4. Banned Opener Check: `check_banned_openers()`

**Lines**: 116-130

**Rule**: No phrases starting sentences

**Banned phrases** (case-insensitive):

- "let's be honest"
- "here's the thing"
- "the truth is"
- "at the end of the day"
- "let's be real"

**Example violation**:

```
Bad:  "Here's the thing: most developers don't read documentation."
Good: "Most developers don't read documentation."
```

### File Targeting

#### Command-Line Mode

If arguments are provided, expand files/directories:

```bash
# Check directory recursively
bash scripts/check-style.sh content/guides/

# Check single file
bash scripts/check-style.sh content/guides/effective-prompting.md
```

Excludes: `CLAUDE.md` and `_index.md` files

#### CI Mode (Default)

When no arguments provided, script runs in CI mode (lines 147-159):

```bash
git diff --name-only --diff-filter=ACMR "origin/${base_ref}...HEAD" | \
    grep '^content/.*\.md$' | \
    grep -v 'CLAUDE\.md' | \
    grep -v '_index\.md'
```

Compares against `origin/$GITHUB_BASE_REF` (defaults to `main`)

### Exempt Files

Lines 19-23:

```bash
EXEMPT_FILES=(
    "2026-02-12-dario-we-dont-know-ai-conscious.md"
)
```

This file is a Dario Amodei transcript and exempt from style checks (relative timeline phrasing rules don't apply to quoted material).

### Exit Codes

- **Exit 0**: All files pass all checks
- **Exit 1**: At least one violation found

Report format:

```
/path/to/file.md:42: em dash character (—) found; use -- instead
  "Some text with — character"

---
Found 1 style violation(s).
```

---

## Build Verification

### Local Testing

```bash
# Start local dev server (with live reload)
make server

# Build to public/ directory
make build

# Clean build artifacts
make clean

# Run style checks
make lint
```

All commands defined in `Makefile` (20 lines, lines 1-20).

### CI Build Process

Hugo v0.155.2 build with specific flags:

```bash
hugo \
  --gc \                  # Garbage collection (remove unused resources)
  --minify \              # Minify output (CSS, JS, HTML)
  --baseURL <pages-url>/  # Set base URL from GitHub Pages config
```

Environment variables during build:

- `HUGO_ENVIRONMENT: production`
- `HUGO_CACHEDIR: /tmp/hugo_cache`
- `TZ: America/Denver`

Build output: `public/` directory

### Build Failures

Build failures prevent deployment. Common failure causes:

- Invalid front matter (YAML parsing errors)
- Broken markdown syntax
- Missing or incorrect Hugo template syntax
- Configuration issues in `hugo.toml`

---

## Hugo Configuration Validation

### Validation Points

`hugo.toml` configuration (26 lines) is validated during build:

```toml
baseURL = 'https://malston.github.io/claude-code-wiki/'
languageCode = 'en-us'
title = 'Claude Code Wiki'
theme = 'hugo-book'
ignoreFiles = ['CLAUDE\.md$']

[params]
  BookTheme = 'auto'
  BookToC = true
  BookSection = '*'
  BookRepo = 'https://github.com/malston/claude-code-wiki'
  BookSearch = true
  BookDateFormat = 'January 2, 2006'

[markup.goldmark.renderer]
  unsafe = true

[markup.highlight]
  style = 'monokai'
  lineNos = false
  noClasses = false

[markup.tableOfContents]
  startLevel = 2
  endLevel = 4
```

**Critical settings**:

- `theme = 'hugo-book'` must match submodule in `themes/hugo-book/`
- `ignoreFiles = ['CLAUDE\.md$']` prevents memory files from being published
- `[markup.goldmark.renderer] unsafe = true` allows HTML in markdown
- `BookSection = '*'` ensures all sections appear in sidebar

---

## Manual Code Review

### Style Review Workflow

Triggered by PR on `content/**/*.md` changes.

**File**: `.github/workflows/CLAUDE.md` (review instructions)

**Reviewer focus** (subjective patterns not caught by automation):

- Contrastive reframes ("It's not X, it's Y")
- Superlative filler (powerful, seamless, elegant, robust)
- Triplet lists (groups of three abstract nouns for rhythm)
- Hedged bold sandwiches (hedge + strong claim + hedge)
- Relative timeline phrasing (new, recently added, improved, legacy)
- Internal implementation names leaking into user prose
- Header casing (title case required)
- Vague claims without concrete examples
- Repetition of same point from multiple angles

**Review severity**: Suggestion-level (advisory, not blocking)

---

## Content Validation Checklist

Before committing content, verify:

### Front Matter

- [ ] `title` field present and uses title case
- [ ] `linkTitle` field present (short version for sidebar)
- [ ] `weight` field present (numeric ordering)
- [ ] For index files: `bookCollapseSection: false`

### Markdown Style

- [ ] No em dash character (`—`)
- [ ] All code fences have language identifiers
- [ ] No triple hyphens used inline
- [ ] No banned opener phrases (let's be honest, here's the thing, etc.)
- [ ] Headers start at level 2 (`##`)
- [ ] No em dashes in body text

### Content Quality

- [ ] Contains at least one concrete example (code, config, command)
- [ ] No contrastive reframes
- [ ] No superlative filler adjectives
- [ ] Specific claims backed by measurements or concrete examples
- [ ] No relative timeline phrasing (new, recently, improved, legacy)
- [ ] No internal implementation type names
- [ ] Scannable (good header structure, code blocks, lists)
- [ ] No repetition of same point
- [ ] Sources credited where applicable

---

## Deployment Process

### Trigger

- Push to `main` branch
- Or manual workflow trigger via GitHub Actions UI

### Steps

1. **Download & verify Hugo** - SHA256 validation
2. **Checkout code** - Recursive submodule fetch
3. **Build site** - `hugo --gc --minify`
4. **Upload artifact** - Build output to GitHub Pages staging
5. **Deploy** - Publish to `https://malston.github.io/claude-code-wiki/`

### Rollback

Since this is a static site on GitHub Pages, rollback means:

- Revert commit on `main`
- Push revert commit
- GitHub Actions automatically rebuilds from reverted content

---

## Testing Gaps and Limitations

### What Is NOT Tested

- **Link validation** - No automated check that internal/external links are valid
- **Metadata consistency** - No check that all pages have required front matter fields
- **Search index generation** - BookTheme generates search index, but index completeness is not validated
- **Page layout** - No visual regression testing
- **SEO** - No automated SEO validation
- **Performance** - No build time benchmarking
- **Content cross-references** - No check that linked pages exist or are correct

### Potential Improvements

1. **Link checker** - Validate all markdown links and external references
2. **Front matter validator** - Ensure all required fields present and correctly typed
3. **Word count analyzer** - Track article length over time
4. **Search index validator** - Verify all content is included in search
5. **Performance benchmarks** - Track build time and output size
6. **Spelling/grammar** - Optional linter for typos and common errors

---

## Troubleshooting

### Style Check Failures

**Problem**: `code fence without language identifier`

**Fix**: Add language identifier to fence opening

```bash
# Before
```

code here

````

# After
```bash
code here
````

````

**Problem**: `em dash character (—) found; use -- instead`

**Fix**: Replace `—` with `--` (two hyphens)

**Problem**: `banned opener phrase: "let's be honest"`

**Fix**: Remove the phrase, state the claim directly

### Build Failures

**Problem**: `error building site: YAML parse error in front matter`

**Cause**: Invalid YAML in front matter

**Fix**: Validate YAML syntax in article header:
```yaml
---
title: "Correct Title Format"
linkTitle: "Short Title"
weight: 1
---
````

**Problem**: `theme not found: hugo-book`

**Cause**: Submodule not initialized

**Fix**:

```bash
git submodule update --init --recursive
```

### Deployment Failures

Check GitHub Actions logs in `//.github/workflows/hugo.yml` run results.

Common causes:

- Build succeeded but artifact upload failed (rare)
- Pages configuration incorrect (check repository settings)
- Branch protection rules preventing deployment

---

## CI Configuration Files Summary

| File                                | Purpose              | Trigger                        | Action                    |
| ----------------------------------- | -------------------- | ------------------------------ | ------------------------- |
| `.github/workflows/style-check.yml` | Lint markdown        | PR on `content/**/*.md`        | Block merge if violations |
| `.github/workflows/hugo.yml`        | Build & deploy       | Push to main or manual         | Deploy to GitHub Pages    |
| `.github/workflows/claude.yml`      | AI assistance        | PR/issue comments with @claude | Optional automation       |
| `scripts/check-style.sh`            | Style validation     | Executed by style-check.yml    | Exit 1 if violations      |
| `Makefile`                          | Local dev automation | Manual execution               | Run Hugo locally          |

# Coding Conventions and Patterns

## Project Overview

The Claude Code Wiki is a Hugo static site (v0.155.2) deploying to GitHub Pages. Content is organized as Markdown with YAML front matter. The site uses the [Hugo Book theme](https://github.com/alex-shpak/hugo-book) as a git submodule.

- **Source**: `/Users/markalston/code/claude-code-wiki/content/`
- **Build**: Hugo with `--gc --minify` flags in production
- **Deployment**: GitHub Actions to GitHub Pages
- **Configuration**: `hugo.toml`

---

## File Organization

### Content Structure

All publishable content lives under `/Users/markalston/code/claude-code-wiki/content/` with these sections:

| Section               | Purpose                                        | Files                                  |
| --------------------- | ---------------------------------------------- | -------------------------------------- |
| `internals/`          | How Claude Code works technically              | 8 articles + `_index.md`               |
| `guides/`             | Practical usage patterns                       | 10 articles + `_index.md`              |
| `extending/`          | Building extensions (subagents, skills, hooks) | 5 articles + `_index.md`               |
| `enterprise-rollout/` | 12-week deployment consulting guide            | 25 articles across 6 phases + appendix |
| `perspectives/`       | Opinion pieces on AI development               | 4 articles + `_index.md`               |
| `training/`           | Role-based learning paths                      | 3 paths + `_index.md`                  |

### Special Files

- `_index.md` - Section landing pages (required for section headers in sidebar)
- `CLAUDE.md` - Project memory files (ignored by Hugo via `ignoreFiles = ['CLAUDE\.md$']`)
- All other `.md` files - Article content

### Excluded from Builds

Hugo configuration at `hugo.toml` line 5:

```toml
ignoreFiles = ['CLAUDE\.md$']
```

---

## Front Matter Conventions

### Standard Article Front Matter

All markdown content files start with YAML front matter:

```yaml
---
title: "Main Article Title: Descriptive Subtitle"
linkTitle: "Short Title for Sidebar"
weight: 1
---
```

**Fields**:

- `title` - Full title displayed at page top. Use title case ("How Context Windows Work").
- `linkTitle` - Shortened version for sidebar navigation (typically 1-3 words).
- `weight` - Determines sidebar ordering within section (lower = higher in list).

### Section Index Front Matter

`_index.md` files for section landing pages:

```yaml
---
title: "Section Name"
weight: 1
bookCollapseSection: false
---
```

- `bookCollapseSection: false` - Keep section expanded in sidebar navigation.

### Example

From `/Users/markalston/code/claude-code-wiki/content/internals/system-prompt.md`:

```yaml
---
title: "The System Prompt: What Claude Reads Before You Say Anything"
linkTitle: "The System Prompt"
weight: 1
---
```

---

## Markdown Style Conventions

### Enforced by Style Checker

The project includes automated style validation in `scripts/check-style.sh` that runs on every PR.

#### Em Dashes

- **FORBIDDEN**: Em dash character (`—`)
- **REQUIRED**: Double hyphen (`--`)

Checked by `check_em_dashes()` and `check_triple_hyphen_em_dashes()`:

- Lines containing `—` are flagged as violations
- Triple hyphens (`---`) used inline (not in tables/YAML) are flagged
- Horizontal rules and table separators are exempted

#### Code Fence Language Identifiers

- **REQUIRED**: All code blocks must have a language identifier after the opening backticks
- **FORBIDDEN**: Bare ` ``` ` without language

Valid:

```bash
#!/bin/bash
echo "example"
```

Valid:

```text
Plain text example
```

Invalid:

```
This fence has no language identifier
```

Checked by `check_bare_code_fences()` in lines 50-73 of `scripts/check-style.sh`.

#### Banned Opener Phrases

The following phrases are automatically rejected by `check_banned_openers()`:

- "let's be honest"
- "here's the thing"
- "the truth is"
- "at the end of the day"
- "let's be real"

These are case-insensitive checks. Example violation from `scripts/check-style.sh` lines 116-130.

### Subjective Style Rules

Enforced via human code review in `.github/workflows/claude-code-review.yml`. See `STYLE-GUIDE.md` for detailed patterns to avoid:

- **Contrastive reframes** ("It's not X, it's Y")
- **Superlative filler** (powerful, seamless, elegant, robust, cutting-edge)
- **Triplet lists** (groups of three abstract nouns for rhythm, not content)
- **Hedged bold sandwiches** (hedge + strong claim + hedge)
- **Relative timeline phrasing** ("new", "recently added", "improved", "legacy" on product timelines)
- **Internal implementation names** (private class names, struct names in user-facing prose)
- **Vague claims** without concrete examples or measurements

### Structure Standards

From `/Users/markalston/code/claude-code-wiki/STYLE-GUIDE.md`:

#### Headers

- Use title case: "How Context Windows Work" not "How context windows work"
- Level 1 (`#`) is article title (from front matter)
- Subsequent headers start at level 2 (`##`)
- No horizontal rules (`---`) as section dividers -- headings suffice

#### Tables

- Reserved for genuinely tabular data
- Executive summary tables at article start are standard
- Do not use tables to format lists

#### Code Examples

- Use fenced code blocks with language identifiers
- Use `text` for plain-text examples
- Use `bash` for shell commands/output
- ASCII diagrams preferred over Mermaid for simple structures

#### Lists

- Use scannable formatting
- Information hierarchy: headers, code blocks, lists break up prose

#### Punctuation

- Oxford comma: yes
- One space after periods
- Contractions are fine

---

## Hugo Configuration

### Base Settings

From `hugo.toml`:

```toml
baseURL = 'https://malston.github.io/claude-code-wiki/'
languageCode = 'en-us'
title = 'Claude Code Wiki'
theme = 'hugo-book'
```

### Parameters

```toml
[params]
  BookTheme = 'auto'              # Light/dark mode auto-detection
  BookToC = true                  # Table of contents per article
  BookSection = '*'               # Show all sections in sidebar
  BookRepo = 'https://github.com/malston/claude-code-wiki'
  BookSearch = true               # Enable search functionality
  BookDateFormat = 'January 2, 2006'
```

### Markdown Processing

```toml
[markup.goldmark.renderer]
unsafe = true                      # Allows HTML in markdown (required for some content)

[markup.highlight]
style = 'monokai'
lineNos = false
noClasses = false

[markup.tableOfContents]
startLevel = 2                     # TOC starts at h2
endLevel = 4                       # TOC includes h2-h4
```

---

## Build Process

### Local Development

```bash
make server    # Start hugo serve with live reload
make build     # Build to public/ directory
make clean     # Remove public/
make lint      # Run style checks
```

From `Makefile` (lines 1-19).

### Production Build

GitHub Actions workflow `.github/workflows/hugo.yml`:

1. **Verify Hugo**: Downloads v0.155.2 with SHA256 checksum validation
2. **Checkout**: Recursive submodule checkout (includes theme)
3. **Build**: `hugo --gc --minify --baseURL <pages-url>`
4. **Deploy**: Upload to GitHub Pages

Build environment:

- `HUGO_ENVIRONMENT: production`
- `HUGO_CACHEDIR: ${{ runner.temp }}/hugo_cache`
- `TZ: America/Denver`

---

## Style Validation

### Automated Checks

Script: `/Users/markalston/code/claude-code-wiki/scripts/check-style.sh`

Runs on PR when paths match `content/**/*.md`.

**Checks performed**:

1. `check_em_dashes()` - Flags `—` character
2. `check_triple_hyphen_em_dashes()` - Flags `---` outside code/tables
3. `check_bare_code_fences()` - Flags ` ``` ` without language
4. `check_banned_openers()` - Flags banned phrase starters

**Exit behavior**:

- Exit 0: All checks pass
- Exit 1: Violations found (blocks merge)

**Exempt files** (line 21-23):

```bash
EXEMPT_FILES=(
    "2026-02-12-dario-we-dont-know-ai-conscious.md"
)
```

### Manual Review

PR trigger: `.github/workflows/claude-code-review.yml` (lines 1-21 in style-check.yml reference)

Review instructions at `.github/workflows/CLAUDE.md` guide reviewers to flag subjective violations from `STYLE-GUIDE.md` using suggestion-level severity.

---

## Writing Conventions

### General Principles

From `CLAUDE.md`:

1. **No contrastive reframes** - State things directly
2. **No superlative filler** - Remove adjectives that don't carry information
3. **No triplet lists** - Each item must carry information, not cadence
4. **No hedged bold sandwiches** - Pick a position, qualify with specifics
5. **No timeline phrasing** - Describe features as they are, not relative to past states
6. **No implementation names** - Don't leak internal type names into user prose
7. **Use `--` not em dashes** - For readability and consistency
8. **Be specific** - If you can't name a concrete example, the claim doesn't belong
9. **Show, don't describe** - Code examples, diagrams, commands beat prose

### Voice

#### Guides and Reference

- Dry, precise, direct
- Imperative or declarative sentences
- Second person ("you") when addressing reader
- First person ("I", "we") fine in introductions only
- State things directly with no buildup or preamble

#### Perspectives

- Opinion pieces can be conversational
- Still no filler, no superlatives
- Take positions clearly
- Respect reader's time

### Content Quality Standards

Good wiki content:

- Teaches something specific the reader can apply immediately
- Contains at least one concrete example (code, config, command)
- Is scannable (headers, code blocks, lists break up prose)
- Doesn't repeat what's in another page (links instead)
- Credits sources when drawing on others' ideas

---

## Build Output

- **Output directory**: `public/`
- **Minification**: Enabled (`--minify`)
- **Garbage collection**: Enabled (`--gc`)
- **Search indexing**: Generated by BookTheme
- **Static files**: Copied from `static/` directory

---

## Project Dependencies

- **Hugo**: v0.155.2 (extended build)
- **Theme**: hugo-book (git submodule in `themes/hugo-book/`)
- **Language**: Markdown + YAML front matter
- **Deployment**: GitHub Pages via Actions

---

## Special Patterns

### Executive Summaries

Articles typically open with an "Executive Summary" section containing:

- Brief 1-2 sentence overview
- Summary table with key information
- Quick-reference list of main points

Example from `content/internals/system-prompt.md` lines 1-20.

### Table of Contents

Generated by Hugo from h2-h4 headers (configured in `hugo.toml`). Manual TOC section appears after executive summary in some articles.

### Diagrams

ASCII art boxes and flow diagrams used for architecture visualization. Example from `content/guides/effective-prompting.md`:

```
┌──────────────────────────────────────────────────┐
│ System Prompt (~12,000-20,000 tokens)            │
│ ├── Core behavior rules                          │
│ └── ...                                          │
├──────────────────────────────────────────────────┤
│ Conversation History (grows each turn)           │
└──────────────────────────────────────────────────┘
```

---

## File Naming

- All lowercase with hyphens: `context-management.md`
- Index files: `_index.md`
- No dates except for special content: `2026-02-12-dario-we-dont-know-ai-conscious.md`

---

## Common Content Paths

### Internals Section

```
/Users/markalston/code/claude-code-wiki/content/internals/
├── _index.md
├── CLAUDE.md
├── system-prompt.md
├── context-management.md
├── prompt-caching.md
├── token-optimization.md
├── extended-thinking.md
└── tool-execution-context.md
```

### Guides Section

```
/Users/markalston/code/claude-code-wiki/content/guides/
├── _index.md
├── CLAUDE.md
├── effective-prompting.md
├── workflow-patterns.md
├── debugging-techniques.md
├── testing-strategies.md
├── model-selection.md
├── memory-organization.md
├── coding-assistants-context.md
├── permissions-enterprise.md
└── spec-driven-development.md
```

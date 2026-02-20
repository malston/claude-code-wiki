# Tech Stack

## Static Site Generator

| Component | Detail                                          |
| --------- | ----------------------------------------------- |
| Generator | Hugo (Go-based)                                 |
| Theme     | hugo-book (git submodule at `themes/hugo-book`) |
| Config    | `hugo.toml`                                     |
| Content   | Markdown files under `content/`                 |

## Content Sections

| Section            | Path                          | Articles |
| ------------------ | ----------------------------- | -------- |
| Internals          | `content/internals/`          | 5        |
| Guides             | `content/guides/`             | 7        |
| Extending          | `content/extending/`          | 5        |
| Enterprise Rollout | `content/enterprise-rollout/` | 25       |
| Perspectives       | `content/perspectives/`       | varies   |

## Tooling

| Tool            | Purpose                                             |
| --------------- | --------------------------------------------------- |
| Makefile        | Build commands (`hugo serve`, `hugo --gc --minify`) |
| scripts/        | Automation scripts (shell)                          |
| STYLE-GUIDE.md  | Content writing rules and anti-patterns             |
| style-check.yml | GitHub Actions workflow enforcing style rules       |

## CI/CD

| Component         | Detail                                                  |
| ----------------- | ------------------------------------------------------- |
| Build             | GitHub Actions (`hugo.yml`)                             |
| Style enforcement | GitHub Actions (`style-check.yml`)                      |
| Code review       | GitHub Actions (`claude-code-review.yml`, `claude.yml`) |
| Deploy target     | GitHub Pages                                            |
| Deploy trigger    | Push to `main` branch                                   |

## Local Development

```bash
hugo serve          # Local dev server with live reload
hugo --gc --minify  # Production build
```

## Languages

- **Markdown** -- all wiki content
- **Shell/Bash** -- Makefile, scripts, CI workflows
- **TOML** -- Hugo configuration
- **YAML** -- GitHub Actions workflows

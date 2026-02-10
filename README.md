# Claude Code Wiki

**[https://www.markalston.net/claude-code-wiki/](https://www.markalston.net/claude-code-wiki/)**

Deep dives into Claude Code internals, patterns, and optimization techniques for getting the most from AI-assisted development.

## Sections

### [Internals](https://www.markalston.net/claude-code-wiki/internals/)

How Claude Code works under the hood -- system prompt anatomy, context window mechanics, prompt caching economics, token optimization, and extended thinking.

### [Guides](https://www.markalston.net/claude-code-wiki/guides/)

How to use Claude Code effectively -- prompting techniques, development workflows, debugging strategies, testing patterns, model selection, memory organization, and permissions.

### [Extending](https://www.markalston.net/claude-code-wiki/extending/)

How to build on Claude Code -- subagents, skills, hooks, MCP servers, integration patterns, custom extensions, and multi-agent teams.

### [Enterprise Rollout](https://www.markalston.net/claude-code-wiki/enterprise-rollout/)

A consulting binder for deploying Claude Code to a 500-developer enterprise with strict network security requirements. Covers infrastructure, platform engineering, phased rollout, and governance across a 12-week engagement.

## Development

Built with [Hugo](https://gohugo.io/) using the [Book theme](https://github.com/alex-shpak/hugo-book). Deployed to GitHub Pages via GitHub Actions.

```bash
# Local development
hugo serve

# Build
hugo --gc --minify
```

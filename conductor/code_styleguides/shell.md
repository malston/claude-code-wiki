# Shell Script Style Guide

## Shebang

Use `#!/usr/bin/env bash` for portability. Never use `#!/bin/bash`.

## Defensive Defaults

Every script starts with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e` -- exit on error
- `set -u` -- treat unset variables as errors
- `set -o pipefail` -- propagate pipe failures

## Variables

- Quote all variable expansions: `"${var}"` not `$var`
- Use `readonly` for constants: `readonly CONFIG_DIR="/etc/myapp"`
- Use `local` for function-scoped variables
- Use UPPER_SNAKE_CASE for exported/environment variables
- Use lower_snake_case for local variables

## Functions

- Use `function_name() {` syntax (no `function` keyword)
- Declare local variables with `local`
- Return meaningful exit codes

```bash
build_site() {
  local output_dir="${1:?output_dir required}"
  hugo --gc --minify -d "${output_dir}"
}
```

## Error Handling

- Check command existence before use: `command -v hugo >/dev/null 2>&1 || { echo "hugo not found"; exit 1; }`
- Use trap for cleanup: `trap cleanup EXIT`
- Print errors to stderr: `echo "error: something failed" >&2`

## Conditionals

- Use `[[ ]]` for tests, not `[ ]`
- Use `(( ))` for arithmetic
- Quote strings in comparisons: `[[ "${var}" == "value" ]]`

## Naming

- Script files use kebab-case: `build-site.sh`, `check-style.sh`
- Functions use snake_case: `build_site`, `check_style`

## Comments

- Add a brief description comment after the shebang
- Comment non-obvious logic
- Don't comment obvious operations

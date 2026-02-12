#!/usr/bin/env bash
set -Eeuo pipefail

# Mechanical style checks for wiki content.
# Runs deterministic regex checks that complement the subjective
# Claude code review. Exits 0 if clean, 1 if violations found.
#
# Usage:
#   bash scripts/check-style.sh [file-or-dir ...]
#
# Without arguments (CI mode): checks files changed in the current PR
# against origin/$GITHUB_BASE_REF (defaults to main).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROOT

violations=0

# --- Helpers ---

report() {
    local file="$1" line="$2" msg="$3" content="$4"
    echo "${file}:${line}: ${msg}"
    echo "  ${content}"
    echo ""
    violations=$((violations + 1))
}

# --- Checks ---

check_em_dashes() {
    local file="$1"
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" == *"—"* ]]; then
            report "$file" "$line_num" "em dash character (—) found; use -- instead" "$line"
        fi
    done < "$file"
}

check_bare_code_fences() {
    local file="$1"
    local line_num=0
    local in_code_block=false
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Match opening or closing fence (``` with optional language)
        if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
            if [[ "$in_code_block" == false ]]; then
                # Opening fence -- check for language identifier
                # Strip leading whitespace and the backticks
                local after_ticks="${line#*\`\`\`}"
                # Trim leading whitespace from remainder
                after_ticks="${after_ticks#"${after_ticks%%[![:space:]]*}"}"
                if [[ -z "$after_ticks" ]]; then
                    report "$file" "$line_num" "code fence without language identifier" "$line"
                fi
                in_code_block=true
            else
                # Closing fence
                in_code_block=false
            fi
        fi
    done < "$file"
}

check_banned_openers() {
    local file="$1"
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Case-insensitive match against banned phrases
        local lower
        lower="$(echo "$line" | tr '[:upper:]' '[:lower:]')"
        for phrase in "let's be honest" "here's the thing" "the truth is" "at the end of the day" "let's be real"; do
            if [[ "$lower" == *"$phrase"* ]]; then
                report "$file" "$line_num" "banned opener phrase: \"${phrase}\"" "$line"
            fi
        done
    done < "$file"
}

# --- File targeting ---

gather_files() {
    if [[ $# -gt 0 ]]; then
        # Arguments provided -- expand files and directories
        for arg in "$@"; do
            if [[ -f "$arg" ]]; then
                echo "$arg"
            elif [[ -d "$arg" ]]; then
                find "$arg" -name '*.md' -not -name 'CLAUDE.md' -not -name '_index.md' -type f
            else
                echo "Warning: ${arg} is not a file or directory, skipping" >&2
            fi
        done
    else
        # CI mode -- diff against base branch
        local base_ref="${GITHUB_BASE_REF:-main}"
        git -C "$REPO_ROOT" diff --name-only --diff-filter=ACMR "origin/${base_ref}...HEAD" \
            | grep '^content/.*\.md$' \
            | grep -v 'CLAUDE\.md' \
            | grep -v '_index\.md' \
            || true
    fi
}

# --- Main ---

main() {
    local files
    files="$(gather_files "$@")"

    if [[ -z "$files" ]]; then
        echo "No markdown files to check."
        exit 0
    fi

    while IFS= read -r file; do
        # Resolve relative paths from repo root
        if [[ ! "$file" = /* ]]; then
            file="${REPO_ROOT}/${file}"
        fi
        if [[ ! -f "$file" ]]; then
            echo "Warning: ${file} not found, skipping" >&2
            continue
        fi
        check_em_dashes "$file"
        check_bare_code_fences "$file"
        check_banned_openers "$file"
    done <<< "$files"

    if [[ $violations -gt 0 ]]; then
        echo "---"
        echo "Found ${violations} style violation(s)."
        exit 1
    fi

    echo "All style checks passed."
    exit 0
}

main "$@"

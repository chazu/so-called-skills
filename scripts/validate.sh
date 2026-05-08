#!/usr/bin/env bash
# validate.sh -- Validate an Agent Skills package
#
# Usage: ./scripts/validate.sh <skill-directory>
#        ./scripts/validate.sh --all
#
# Validates:
#   - SKILL.md exists
#   - YAML frontmatter is parseable
#   - Required fields (name, description) are present
#   - name matches directory name
#   - description is non-empty
#   - Body is under token limit (~5000 tokens ≈ 20000 chars)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

error() {
    echo -e "  ${RED}ERROR${NC}: $1"
    ((ERRORS++))
}

warn() {
    echo -e "  ${YELLOW}WARN${NC}: $1"
    ((WARNINGS++))
}

ok() {
    echo -e "  ${GREEN}OK${NC}: $1"
}

validate_skill() {
    local skill_dir="$1"
    local dir_name
    dir_name=$(basename "$skill_dir")

    echo ""
    echo "Validating: $dir_name"
    echo "  Path: $skill_dir"

    # Check SKILL.md exists
    local skill_md="$skill_dir/SKILL.md"
    if [[ ! -f "$skill_md" ]]; then
        error "SKILL.md not found"
        return 1
    fi
    ok "SKILL.md exists"

    # Extract frontmatter
    local frontmatter
    frontmatter=$(awk '/^---$/{if(++c==2)exit}c' "$skill_md" | tail -n +2)

    if [[ -z "$frontmatter" ]]; then
        error "No YAML frontmatter found (must be between --- delimiters)"
        return 1
    fi
    ok "YAML frontmatter found"

    # Parse name field
    local name
    name=$(echo "$frontmatter" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
    if [[ -z "$name" ]]; then
        error "Missing required field: name"
    else
        ok "name: $name"

        # Check name matches directory
        if [[ "$name" != "$dir_name" ]]; then
            warn "name '$name' does not match directory name '$dir_name'"
        fi

        # Check name format
        if ! echo "$name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
            warn "name should contain only lowercase letters, numbers, hyphens, and underscores"
        fi

        # Check name length
        if [[ ${#name} -gt 64 ]]; then
            warn "name exceeds 64 characters"
        fi
    fi

    # Parse description field
    local description
    description=$(echo "$frontmatter" | awk '
        /^description:/ {
            sub(/^description:[[:space:]]*/, "")
            if ($0 ~ /^[|>]/) {
                # Block scalar -- read following indented lines
                desc = ""
                while ((getline line) > 0) {
                    if (line ~ /^[[:space:]]/) {
                        sub(/^[[:space:]]+/, "", line)
                        desc = desc " " line
                    } else {
                        break
                    }
                }
                sub(/^[[:space:]]+/, "", desc)
                print desc
            } else {
                # Inline value
                gsub(/^["'\'']|["'\'']$/, "")
                print
            }
            exit
        }
    ')

    if [[ -z "$description" ]]; then
        error "Missing required field: description"
    else
        local desc_len=${#description}
        if [[ $desc_len -gt 1024 ]]; then
            warn "description exceeds 1024 characters ($desc_len chars)"
        fi
        ok "description present ($desc_len chars)"
    fi

    # Check body size
    local body
    body=$(awk 'BEGIN{c=0} /^---$/{c++; if(c==2){found=1; next}} found{print}' "$skill_md")
    local body_chars=${#body}
    local body_lines
    body_lines=$(echo "$body" | wc -l | tr -d ' ')

    if [[ $body_chars -gt 20000 ]]; then
        warn "Body is large (~$((body_chars / 4)) tokens). Recommended: <5000 tokens"
    fi
    if [[ $body_lines -gt 500 ]]; then
        warn "Body has $body_lines lines. Recommended: <500 lines"
    fi
    ok "Body: $body_lines lines, ~$((body_chars / 4)) tokens"

    # Check for README.md
    if [[ -f "$skill_dir/README.md" ]]; then
        ok "README.md present"
    else
        warn "No README.md (recommended)"
    fi

    return 0
}

# Main
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [[ "${1:-}" == "--all" ]]; then
    echo "Validating all skills in $REPO_DIR/skills/"
    for skill_dir in "$REPO_DIR"/skills/*/; do
        [[ -d "$skill_dir" ]] || continue
        validate_skill "$skill_dir" || true
    done
elif [[ -n "${1:-}" ]]; then
    # Resolve relative to repo root if not absolute
    target="$1"
    if [[ ! "$target" = /* ]]; then
        target="$REPO_DIR/$target"
    fi
    validate_skill "$target"
else
    echo "Usage: $0 <skill-directory>"
    echo "       $0 --all"
    exit 1
fi

echo ""
echo "================================"
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}FAILED${NC}: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}PASSED${NC} with $WARNINGS warning(s)"
    exit 0
else
    echo -e "${GREEN}PASSED${NC}: All checks passed"
    exit 0
fi

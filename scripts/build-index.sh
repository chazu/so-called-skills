#!/usr/bin/env bash
# build-index.sh -- Generate skill_index.json from all skills
#
# Usage: ./scripts/build-index.sh
#
# Outputs skill_index.json at the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="$REPO_DIR/skill_index.json"

echo "Building skill index..."

# Start JSON array
echo "[" > "$INDEX_FILE"

first=true
for skill_dir in "$REPO_DIR"/skills/*/; do
    [[ -d "$skill_dir" ]] || continue

    skill_md="$skill_dir/SKILL.md"
    [[ -f "$skill_md" ]] || continue

    dir_name=$(basename "$skill_dir")

    # Skip template
    [[ "$dir_name" == "_template" ]] && continue

    # Extract frontmatter
    frontmatter=$(awk '/^---$/{if(++c==2)exit}c' "$skill_md" | tail -n +2)
    [[ -z "$frontmatter" ]] && continue

    # Parse fields
    name=$(echo "$frontmatter" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
    [[ -z "$name" ]] && name="$dir_name"

    # Parse description (handle multiline)
    description=$(echo "$frontmatter" | awk '
        /^description:/ {
            sub(/^description:[[:space:]]*/, "")
            if ($0 ~ /^[|>]/) {
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
                gsub(/^["'\''"]|["'\''"]$/, "")
                print
            }
            exit
        }
    ')

    # Parse optional metadata
    version=$(echo "$frontmatter" | grep -E '^[[:space:]]*version:' | head -1 | sed 's/.*version:[[:space:]]*//' | tr -d '"' | tr -d "'")
    author=$(echo "$frontmatter" | grep -E '^[[:space:]]*author:' | head -1 | sed 's/.*author:[[:space:]]*//' | tr -d '"' | tr -d "'")
    license_field=$(echo "$frontmatter" | grep -E '^license:' | head -1 | sed 's/^license:[[:space:]]*//' | tr -d '"' | tr -d "'")

    # Check for evals
    has_evals=false
    [[ -d "$skill_dir/evals" ]] && has_evals=true

    # Check for scripts
    has_scripts=false
    [[ -d "$skill_dir/scripts" ]] && [[ "$(ls -A "$skill_dir/scripts/" 2>/dev/null | grep -v '.gitkeep')" ]] && has_scripts=true

    # Escape strings for JSON
    description_escaped=$(echo "$description" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/[[:space:]]*$//')

    if [[ "$first" == true ]]; then
        first=false
    else
        echo "  ," >> "$INDEX_FILE"
    fi

    cat >> "$INDEX_FILE" << EOF
  {
    "name": "$name",
    "description": "$description_escaped",
    "directory": "skills/$dir_name",
    "version": "${version:-0.1.0}",
    "author": "${author:-}",
    "license": "${license_field:-MIT}",
    "has_evals": $has_evals,
    "has_scripts": $has_scripts,
    "indexed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
EOF

done

echo "]" >> "$INDEX_FILE"

# Count skills
count=$(grep -c '"name"' "$INDEX_FILE" || echo 0)
echo "Generated $INDEX_FILE with $count skill(s)"

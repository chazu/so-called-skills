#!/usr/bin/env bash
# install.sh -- Install skills to a discovery directory
#
# Usage:
#   ./install.sh --target claude     # → ~/.claude/skills/
#   ./install.sh --target agents     # → ~/.agents/skills/
#   ./install.sh --target <path>     # → custom path
#   ./install.sh --skill <name> --target claude  # Install one skill
#
# Options:
#   --target <claude|agents|path>  Where to install (required)
#   --skill <name>                 Install a single skill (default: all)
#   --link                         Symlink instead of copy
#   --dry-run                      Show what would be done

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
SKILLS_DIR="$REPO_DIR/skills"

TARGET=""
SKILL_NAME=""
USE_LINK=false
DRY_RUN=false

usage() {
    echo "Usage: $0 --target <claude|agents|path> [--skill <name>] [--link] [--dry-run]"
    echo ""
    echo "Targets:"
    echo "  claude    Install to ~/.claude/skills/"
    echo "  agents    Install to ~/.agents/skills/ (cross-client)"
    echo "  <path>    Install to a custom directory"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --skill)
            SKILL_NAME="$2"
            shift 2
            ;;
        --link)
            USE_LINK=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    usage
fi

# Resolve target
case "$TARGET" in
    claude)
        DEST="$HOME/.claude/skills"
        ;;
    agents)
        DEST="$HOME/.agents/skills"
        ;;
    *)
        DEST="$TARGET"
        ;;
esac

echo "Installing skills to: $DEST"
[[ "$DRY_RUN" == true ]] && echo "(dry run)"

# Create destination
if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$DEST"
fi

install_skill() {
    local src="$1"
    local name
    name=$(basename "$src")

    # Skip template
    [[ "$name" == "_template" ]] && return

    # Skip if no SKILL.md
    [[ -f "$src/SKILL.md" ]] || return

    local dst="$DEST/$name"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ "$USE_LINK" == true ]]; then
            echo "  Would symlink: $src → $dst"
        else
            echo "  Would copy: $src → $dst"
        fi
        return
    fi

    # Remove existing
    if [[ -e "$dst" ]] || [[ -L "$dst" ]]; then
        rm -rf "$dst"
    fi

    if [[ "$USE_LINK" == true ]]; then
        ln -s "$(cd "$src" && pwd)" "$dst"
        echo "  Linked: $name"
    else
        cp -r "$src" "$dst"
        echo "  Copied: $name"
    fi
}

# Install
if [[ -n "$SKILL_NAME" ]]; then
    src="$SKILLS_DIR/$SKILL_NAME"
    if [[ ! -d "$src" ]]; then
        echo "Error: Skill not found: $src"
        exit 1
    fi
    install_skill "$src"
else
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        install_skill "$skill_dir"
    done
fi

echo ""
echo "Done."

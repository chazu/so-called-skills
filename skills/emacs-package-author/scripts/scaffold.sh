#!/usr/bin/env bash
# Scaffold a new Emacs package directory.
# Usage: scaffold.sh <pkg-name> [--tool eask|cask|eldev]
set -euo pipefail

TARGET="${1:-}"
TOOL="eask"

if [[ -z "$TARGET" ]]; then
  echo "usage: $0 <pkg-name|path> [--tool eask|cask|eldev]" >&2
  exit 1
fi
PKG="$(basename "$TARGET")"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$TOOL" in
  eask|cask|eldev) ;;
  *) echo "tool must be eask|cask|eldev" >&2; exit 1 ;;
esac

REF="$(cd "$(dirname "$0")/.." && pwd)/references"
YEAR="$(date +%Y)"
TODAY="$(date +%Y-%m-%d)"

mkdir -p "$TARGET"/{test,docs,.github/workflows}
cd "$TARGET"

# Main elisp file.
sed -e "s/PKG/${PKG}/g" -e "s/YEAR/${YEAR}/g" -e "s/YYYY-MM-DD/${TODAY}/g" \
    "$REF/header-template.el" > "${PKG}.el"

# README.
sed -e "s/PKG/${PKG}/g" "$REF/README.template.md" > README.md

# CI.
cp "$REF/github-actions-test.yml" .github/workflows/test.yml

# Build tool config.
case "$TOOL" in
  eask)
    sed -e "s/PKG/${PKG}/g" "$REF/Eask.example" > Eask
    TEST_CMD="eask test buttercup"
    ;;
  cask)
    sed -e "s/PKG/${PKG}/g" "$REF/Cask.example" > Cask
    TEST_CMD="cask exec buttercup -L . test/"
    ;;
  eldev)
    sed -e "s/PKG/${PKG}/g" "$REF/Eldev.example" > Eldev
    TEST_CMD="eldev test"
    ;;
esac

# Test stub.
cat > "test/${PKG}-test.el" <<EOF
;;; ${PKG}-test.el --- Tests for ${PKG} -*- lexical-binding: t; -*-
(require 'buttercup)
(require '${PKG})

(describe "${PKG}"
  (it "loads"
    (expect (featurep '${PKG}) :to-be-truthy)))

(provide '${PKG}-test)
;;; ${PKG}-test.el ends here
EOF

# CHANGELOG, LICENSE placeholder, .gitignore.
cat > CHANGELOG.md <<EOF
# Changelog

## [Unreleased]

## [0.1.0] - ${TODAY}
- Initial release.
EOF

cat > .gitignore <<'EOF'
/.eask/
/dist/
/elpa/
*.elc
EOF

echo "scaffolded ${PKG} with ${TOOL}"
echo "next:"
echo "  cd ${PKG}"
echo "  git init && git add -A && git commit -m 'initial commit'"
echo "  ${TEST_CMD}"

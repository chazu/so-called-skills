# emacs-package-author

Agent skill for authoring production-grade Emacs Lisp packages.

Covers:
- File layout + symbol-prefix conventions
- `package.el` headers (`Package-Requires`, `lexical-binding`, autoloads)
- Build tooling: **Eask** (recommended), **Eldev**, **Cask**
- Testing: **Buttercup** (default) and **ERT**
- GitHub Actions CI matrix across Emacs 28.1 / 29.4 / 30.1 / snapshot
- README with `straight.el` + `use-package` install snippets
- Detailed docs (Texinfo / `docs/`)
- MELPA submission checklist

## Files

- `SKILL.md` — agent instructions
- `references/header-template.el` — main `.el` skeleton
- `references/Eask.example`, `Cask.example`, `Eldev.example` — build configs
- `references/README.template.md` — README with install/config blocks
- `references/github-actions-test.yml` — CI workflow
- `scripts/scaffold.sh` — bootstrap new pkg directory

## Quick start

```bash
skills/emacs-package-author/scripts/scaffold.sh my-pkg --tool eask
cd my-pkg
eask install-deps --dev && eask test buttercup
```

## License

MIT (skill itself). Templates inside emit GPL-3.0-or-later by default; change to suit your project.

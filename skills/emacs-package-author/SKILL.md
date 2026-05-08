---
name: emacs-package-author
description: >
  Use when creating, scaffolding, refactoring, or maintaining Emacs Lisp
  packages and libraries. Triggers on: "write emacs package", "elisp library",
  "MELPA submission", "package.el header", "Cask/Eask/Eldev setup", or any
  request involving a `.el` file with a `Package-Requires` header. Covers
  layout, headers, build tooling (Eask/Eldev/Cask), testing (Buttercup/ERT),
  CI, README with straight+use-package install snippets, and detailed docs.
metadata:
  author: chazu
  version: 0.1.0
  tags:
    - emacs
    - elisp
    - package
    - melpa
    - eask
    - eldev
    - cask
    - buttercup
license: MIT
---

# Emacs Package Author

Author production-grade Emacs Lisp packages. Follow MELPA conventions, ship tests + CI, document install with `straight.el` + `use-package`.

## When to Use

- User asks to create new Emacs package or elisp library.
- User wants to refactor `.el` file for MELPA submission.
- User adds tests, CI, lint, or build tooling to existing pkg.
- User mentions: `package.el`, `Package-Requires`, `Cask`, `Eask`, `Eldev`, `buttercup`, `package-lint`, `MELPA`.

## Prerequisites

- Emacs 28.1+ installed (target lowest supported version explicitly).
- One build tool installed: `eask` (recommended), `eldev`, or `cask`.
- `git` for repo + MELPA recipe.

## File Layout

```
my-pkg/
├── my-pkg.el              # main entry, full headers
├── my-pkg-core.el         # optional submodules, prefix all symbols
├── test/
│   └── my-pkg-test.el     # buttercup or ert
├── docs/                  # optional extended docs
├── README.md
├── CHANGELOG.md
├── LICENSE
├── Eask                   # OR Cask, OR Eldev (pick one)
└── .github/workflows/test.yml
```

Rules:
- Pkg name = directory name = main `.el` filename = symbol prefix.
- All public defs prefixed `my-pkg-`. Internal: `my-pkg--`.
- One `provide` per file matching filename.

## Step 1 — Scaffold

Use `scripts/scaffold.sh <pkg-name> --tool eask|cask|eldev` to generate skeleton with headers, build file, test stub, CI workflow, README.

Manual scaffold: copy templates from `references/` and substitute pkg name.

## Step 2 — Headers (mandatory)

Every `.el` file in pkg starts with full headers. Main file template at `references/header-template.el`. Required keys:

```elisp
;;; my-pkg.el --- Short summary, no period, no "Emacs" word -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Author Name

;; Author: Author Name <email@example.com>
;; Maintainer: Author Name <email@example.com>
;; URL: https://github.com/user/my-pkg
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: convenience, tools
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; One-paragraph description. Usage example.

;;; Code:

(require 'subr-x)

(defgroup my-pkg nil
  "Customization for my-pkg."
  :group 'convenience
  :prefix "my-pkg-")

(defcustom my-pkg-option nil
  "Docstring imperative, ends with period."
  :type 'boolean
  :group 'my-pkg)

;;;###autoload
(defun my-pkg-command ()
  "User-facing command."
  (interactive)
  ...)

(provide 'my-pkg)
;;; my-pkg.el ends here
```

Header rules:
- `lexical-binding: t` mandatory.
- `Package-Requires` lists every external dep + min Emacs. Pin versions.
- `Version` follows semver. Bump on every release.
- `;;;###autoload` cookie ONLY on user-facing entry points.
- Subfiles drop `Package-Requires` but keep `lexical-binding`, `Commentary`, `Code`, `provide`, ends-here.
- Use `cl-lib` not deprecated `cl`. Use `seq`, `subr-x`, `map` from core.

## Step 3 — Build Tool

Pick one. Recommendation: **Eask** (modern, sandboxed, cross-platform binary, 80+ commands, builtin linters).

### Eask (recommended)

`Eask` file at repo root:

```elisp
(package "my-pkg" "0.1.0" "Short summary")
(website-url "https://github.com/user/my-pkg")
(keywords "convenience" "tools")

(package-file "my-pkg.el")
(files "*.el" "test/*.el")

(script "test" "eask test buttercup")
(script "lint" "eask lint package && eask lint checkdoc")

(source 'gnu)
(source 'melpa)

(depends-on "emacs" "28.1")

(development
 (depends-on "buttercup")
 (depends-on "package-lint"))
```

Common commands:
```bash
eask install-deps --dev
eask compile                  # byte-compile, warnings as errors with --strict
eask lint package             # package-lint
eask lint checkdoc            # docstring conventions
eask lint indent              # indentation
eask test buttercup           # run buttercup specs
eask test ert                 # run ert tests
eask package                  # build distributable
```

Full template: `references/Eask.example`.

### Eldev (alternative)

Pure-elisp build tool. Isolates project deps. Config = `Eldev` file (elisp).
Template: `references/Eldev.example`. Run `eldev test`, `eldev lint`, `eldev compile -W`.

### Cask (legacy)

Still common in older pkgs. Config = `Cask` file.
Template: `references/Cask.example`. Run `cask install`, `cask exec buttercup -L . test/`.

## Step 4 — Tests

Default: **Buttercup** (BDD, `describe`/`it`, `before-each`/`after-each`, spies, CI-friendly).

`test/my-pkg-test.el`:

```elisp
;;; my-pkg-test.el --- Tests -*- lexical-binding: t; -*-
(require 'buttercup)
(require 'my-pkg)

(describe "my-pkg-command"
  :var (tmp)
  (before-each (setq tmp (generate-new-buffer "*test*")))
  (after-each  (kill-buffer tmp))

  (it "does the thing"
    (with-current-buffer tmp
      (my-pkg-command)
      (expect (buffer-string) :to-equal "expected"))))

(provide 'my-pkg-test)
;;; my-pkg-test.el ends here
```

`lexical-binding: t` mandatory in test files. Test file naming: `<pkg>-test.el` or `test/test-<pkg>.el`.

ERT acceptable for tiny pkgs without dev deps:
```elisp
(ert-deftest my-pkg-test-basic ()
  (should (equal (my-pkg-fn 1) 2))
  (should-error (my-pkg-fn nil)))
```

Coverage: add `undercover` to dev deps, push to Coveralls in CI.

## Step 5 — CI

GitHub Actions matrix across Emacs 28.1, 29.4, 30.1, snapshot. Template at `references/github-actions-test.yml`. Uses `jcs090218/setup-emacs` + `emacs-eask/setup-eask`. Two jobs: `test` (matrix) + `lint` (single). Fail on byte-compile warnings.

## Step 6 — README (mandatory)

Template: `references/README.template.md`. Must include:

1. Title + 1-line summary.
2. Badges: MELPA, CI status, license.
3. **Installation** — at minimum these three:
   - `straight.el` + `use-package`:
     ```elisp
     (use-package my-pkg
       :straight (my-pkg :type git :host github :repo "user/my-pkg"))
     ```
   - `use-package` from MELPA:
     ```elisp
     (use-package my-pkg :ensure t)
     ```
   - Manual: `M-x package-install RET my-pkg RET`.
4. **Configuration** — full `use-package` block with `:custom`, `:bind`, `:hook`, `:config`.
5. **Usage** — entry commands, keybindings table.
6. **Customization** — `defcustom` reference table (name, type, default, purpose).
7. **Contributing**, **License**, **Changelog** links.

## Step 7 — Detailed Docs

For non-trivial pkgs, ship Texinfo manual:
- `docs/my-pkg.texi` → compile to `my-pkg.info` → `C-h i` integration.
- Add to `Eask`: `(files "*.el" "*.info" "dir")`.

Alternative: `docs/` markdown directory:
- `getting-started.md`, `cookbook.md`, `api.md`, `faq.md`.

Docstring rules:
- First sentence ≤ first line, imperative ("Return X.", not "Returns X.").
- ARGS in UPPERCASE.
- `\\[command-name]` renders current keybinding.
- `\\<keymap>` switches reference keymap.

## Step 8 — Lint Before Ship

Mandatory clean runs:
```bash
eask lint package      # package-lint, MELPA-blocking issues
eask lint checkdoc     # docstring conventions
eask compile --strict  # byte-compile, warnings as errors
```

`package-lint` MUST be clean before MELPA submission.

## Step 9 — MELPA Submission

1. Tag release: `git tag v0.1.0 && git push --tags`.
2. Fork `melpa/melpa`.
3. Add recipe at `recipes/my-pkg`:
   ```elisp
   (my-pkg :fetcher github :repo "user/my-pkg")
   ```
4. Verify locally: `make recipes/my-pkg`.
5. PR to melpa/melpa. Address reviewer feedback.

## Edge Cases

- **Emacs version compat**: `when-let*` exists 26+, `when-let` deprecated 29+. Use `when-let*` for both args; gate with `(if (fboundp ...) ...)` if supporting older.
- **No `cl`**: use `cl-lib` always. `(require 'cl-lib)`.
- **Autoloads**: only on commands users invoke directly. Internal helpers must NOT have cookie.
- **Byte-compile warnings**: free vars, unused lexicals. Fix root cause, do not suppress.
- **Subfile circular requires**: factor common code into `-core.el`. Subfiles `require` core, not each other.
- **MELPA stable vs unstable**: stable = git tags. Tag every release.
- **License mismatch**: `LICENSE` file must match `SPDX-License-Identifier` header. GPL-3.0-or-later most common.

## References

- `references/header-template.el` — full main-file skeleton.
- `references/Eask.example`, `references/Cask.example`, `references/Eldev.example` — build tool configs.
- `references/README.template.md` — README with install/config snippets.
- `references/github-actions-test.yml` — CI matrix workflow.
- `scripts/scaffold.sh` — bootstrap new pkg directory.

External:
- Emacs Package Developer's Handbook: https://alphapapa.github.io/emacs-package-dev-handbook/
- Eask docs: https://emacs-eask.github.io/
- Eldev: https://emacs-eldev.github.io/eldev/
- Cask: https://cask.github.io/
- Buttercup: https://github.com/jorgenschaefer/emacs-buttercup
- ERT manual: https://www.gnu.org/software/emacs/manual/html_mono/ert.html
- MELPA: https://github.com/melpa/melpa
- Elisp Simple Packages: https://www.gnu.org/software/emacs/manual/html_node/elisp/Simple-Packages.html

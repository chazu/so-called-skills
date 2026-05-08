# PKG

> One-line tagline describing what PKG does.

[![MELPA](https://melpa.org/packages/PKG-badge.svg)](https://melpa.org/#/PKG)
[![CI](https://github.com/USER/PKG/actions/workflows/test.yml/badge.svg)](https://github.com/USER/PKG/actions/workflows/test.yml)
[![License: GPL v3+](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Short paragraph: what problem PKG solves, who it is for, screenshot or asciinema link.

## Installation

### `straight.el` + `use-package` (recommended for tinkerers)

```elisp
(use-package PKG
  :straight (PKG :type git :host github :repo "USER/PKG")
  :commands (PKG-command PKG-mode)
  :custom
  (PKG-option t)
  :bind
  (("C-c p" . PKG-command))
  :hook
  (prog-mode . PKG-mode)
  :config
  ;; Post-load setup.
  (setq PKG-extra 'value))
```

### `use-package` from MELPA

```elisp
(use-package PKG
  :ensure t
  :custom
  (PKG-option t)
  :bind (("C-c p" . PKG-command)))
```

Add MELPA first if not already present:

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
```

### Manual

```
M-x package-install RET PKG RET
```

Or clone and add to `load-path`:

```elisp
(add-to-list 'load-path "/path/to/PKG")
(require 'PKG)
```

## Configuration

Minimal:

```elisp
(use-package PKG :ensure t)
```

Full example:

```elisp
(use-package PKG
  :ensure t
  :custom
  (PKG-option t                     "Enable feature X.")
  (PKG-other-option 42              "Tune Y.")
  :bind
  (:map PKG-mode-map
        ("C-c p p" . PKG-command)
        ("C-c p q" . PKG-quit))
  :hook
  ((prog-mode . PKG-mode)
   (after-init . PKG-global-setup))
  :config
  (PKG-register-backend 'my-backend))
```

## Usage

| Command          | Default Binding | Description                |
|------------------|-----------------|----------------------------|
| `PKG-command`    | `C-c p p`       | Run main action.           |
| `PKG-mode`       | —               | Toggle minor mode.         |
| `PKG-quit`       | `C-c p q`       | Tear down state.           |

## Customization

| Option              | Type    | Default | Description                |
|---------------------|---------|---------|----------------------------|
| `PKG-option`        | boolean | `nil`   | Toggle feature X.          |
| `PKG-other-option`  | integer | `42`    | Threshold for Y.           |

Run `M-x customize-group RET PKG RET` for the full UI.

## Documentation

- Manual: `C-h i d m PKG RET` (after install).
- Online: [docs/](docs/).

## Contributing

PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Run `eask test buttercup && eask lint package` before submitting.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

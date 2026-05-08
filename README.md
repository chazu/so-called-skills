# Agent Skills Repository

A curated collection of reusable [Agent Skills](https://agentskills.io) for Claude Code, Cursor, Hive, and other compatible AI coding agents.

## What are Agent Skills?

Skills are folders containing a `SKILL.md` file that teaches an agent how to perform a specific task. They can also bundle scripts, templates, and reference materials. Skills are loaded on demand -- the agent sees a lightweight catalog at startup and pulls in full instructions only when relevant.

```
skill-name/
├── SKILL.md              # Required: metadata + instructions
├── scripts/              # Optional: executable code
├── references/           # Optional: supplementary docs
├── assets/               # Optional: templates, data files
└── evals/                # Optional: test cases and assertions
```

## Quick Start

### Install a skill

Copy a skill folder into one of the discovery directories:

```bash
# For Claude Code / Jcode (user-level)
cp -r skills/my-skill ~/.claude/skills/

# Cross-client (works with Claude Code, Cursor, Hive, etc.)
cp -r skills/my-skill ~/.agents/skills/

# Project-level (shared with your repo)
cp -r skills/my-skill .claude/skills/
# or cross-client:
cp -r skills/my-skill .agents/skills/
```

### Install all skills

```bash
# Symlink everything to your user skills directory
./install.sh --target claude   # → ~/.claude/skills/
./install.sh --target agents   # → ~/.agents/skills/
```

## Available Skills

| Skill | Description | Status |
|-------|-------------|--------|
| `_template` | Starter template for creating new skills | -- |

> Skills will be listed here as they are added.

## Creating a New Skill

```bash
# 1. Copy the template
cp -r skills/_template skills/my-new-skill

# 2. Edit SKILL.md with your instructions
$EDITOR skills/my-new-skill/SKILL.md

# 3. Validate
./scripts/validate.sh skills/my-new-skill

# 4. Submit a PR
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

## Skill Format (SKILL.md)

Every skill requires a `SKILL.md` with YAML frontmatter:

```markdown
---
name: my-skill
description: >
  What this skill does and when to use it. Be specific --
  this is what the agent uses to decide whether to activate it.
---

# My Skill

## When to Use
Use this skill when...

## Steps
1. First, check...
2. Then, do...

## Edge Cases
- If X happens, do Y...
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase letters, numbers, hyphens. Must match directory name. Max 64 chars. |
| `description` | Yes | What the skill does and when to use it. Max 1024 chars. |
| `license` | No | License name or reference to a bundled LICENSE file. |
| `compatibility` | No | Environment requirements (e.g., "Requires git, docker"). |
| `metadata` | No | Arbitrary key-value pairs (author, version, etc.). |
| `allowed-tools` | No | Space-delimited list of pre-approved tools. |

### Writing Tips

- **Be procedural**: Step-by-step instructions work better than abstract descriptions.
- **Keep it focused**: Stay under 500 lines / 5000 tokens. Move detailed reference material to `references/`.
- **Use relative paths**: Reference bundled files with `scripts/run.py`, `references/guide.md`.
- **Include examples**: Show sample inputs and expected outputs.
- **Cover edge cases**: Tell the agent what to do when things go wrong.

## How Skills Are Loaded (Progressive Disclosure)

| Tier | What | When | Cost |
|------|------|------|------|
| 1. Catalog | Name + description | Session start | ~50-100 tokens/skill |
| 2. Instructions | Full SKILL.md body | Skill activated | <5000 tokens recommended |
| 3. Resources | Scripts, references | On demand | Varies |

## Cross-Client Compatibility

Skills in this repository follow the open [Agent Skills specification](https://agentskills.io/specification) and work with:

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) / Jcode
- [Cursor](https://cursor.com)
- [Hive](https://github.com/aden-hive/hive)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [GitHub Copilot](https://github.com/features/copilot)
- Other Agent Skills-compatible tools

## Repository Structure

```
skills/                     # All skill packages
  _template/                # Starter template
  skill-name/               # One directory per skill
    SKILL.md
    scripts/
    references/
    assets/
    evals/
scripts/                    # Repository tooling
  validate.sh               # Validate a skill package
  build-index.sh            # Generate skill_index.json
skill_index.json            # Auto-generated index of all skills
install.sh                  # Install skills to your system
CONTRIBUTING.md             # How to contribute
LICENSE                     # Repository license (MIT)
```

## License

This repository is licensed under the [MIT License](LICENSE). Individual skills may specify their own license in their `SKILL.md` frontmatter.

# AGENTS.md

Guidance for AI agents working in this repository.

## Repository Purpose

This is a curated collection of reusable **Agent Skills** following the open
[agentskills.io](https://agentskills.io) specification. Skills are portable
across Claude Code, Jcode, Cursor, Hive, Gemini CLI, and other compatible tools.

## Repository Layout

```
skills/              # All skill packages (one directory per skill)
  _template/         # Starter template -- copy this to create a new skill
  <skill-name>/      # Each skill has at minimum a SKILL.md
scripts/             # Repo tooling (validate, build-index)
skill_index.json     # Auto-generated index of published skills
install.sh           # Installs skills to user discovery directories
```

## Conventions

- Every skill lives in `skills/<name>/` and **must** contain a `SKILL.md`.
- The `name` field in SKILL.md frontmatter **must** match the directory name.
- Descriptions should be specific about **what** the skill does and **when** to use it.
- Keep SKILL.md body under 500 lines / 5000 tokens. Use `references/` for detail.
- Use relative paths when referencing bundled files from SKILL.md.
- Run `./scripts/validate.sh skills/<name>` before committing a skill.
- Run `./scripts/build-index.sh` after adding or modifying skills.

## SKILL.md Format

```yaml
---
name: skill-name          # Required. Lowercase, hyphens, matches directory.
description: >            # Required. What it does + when to activate.
  Detailed description of the skill and trigger conditions.
metadata:                  # Optional.
  author: name
  version: 0.1.0
  tags: [tag1, tag2]
license: MIT               # Optional.
compatibility: "Requires X"  # Optional.
allowed-tools: "Bash Edit"   # Optional. Space-delimited.
---

# Skill Title

Instructions for the agent (markdown body)...
```

## Skill Directory Structure

```
my-skill/
├── SKILL.md              # Required: metadata + agent instructions
├── README.md             # Recommended: human-readable documentation
├── scripts/              # Optional: executable helpers
├── references/           # Optional: supplementary docs
├── assets/               # Optional: templates, data files
└── evals/                # Optional: test cases (evals.json)
```

## Workflow for Adding a Skill

1. `cp -r skills/_template skills/<new-name>`
2. Edit `skills/<new-name>/SKILL.md` -- update frontmatter and body
3. `./scripts/validate.sh skills/<new-name>` -- fix any errors
4. `./scripts/build-index.sh` -- regenerate the index
5. Commit both the skill directory and updated `skill_index.json`

## Quality Checklist

- [ ] `name` matches directory name
- [ ] Description is specific (not vague)
- [ ] Instructions are procedural (numbered steps)
- [ ] Edge cases and error handling documented
- [ ] Validation passes cleanly
- [ ] No secrets, API keys, or personal data

## Do Not

- Do not modify `skills/_template/` unless improving the template itself.
- Do not hand-edit `skill_index.json` -- it is auto-generated.
- Do not add skills that require proprietary tools without noting it in `compatibility`.

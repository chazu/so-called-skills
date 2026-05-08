# Agent Skills Repository

This repository contains reusable Agent Skills that can be discovered and
activated by Claude Code, Jcode, and other Agent Skills-compatible tools.

## For Agents

When working in this repository:
- Skills live in `skills/<name>/` directories
- Each skill has a `SKILL.md` with YAML frontmatter and markdown instructions
- Use `./scripts/validate.sh <path>` to validate a skill
- Use `./scripts/build-index.sh` to regenerate `skill_index.json`
- Follow the Agent Skills specification at https://agentskills.io/specification

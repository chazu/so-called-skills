# Contributing

Thank you for contributing to this skills repository! This guide covers how to create, validate, and submit a new skill.

## Quick Start

```bash
# 1. Fork and clone this repo
git clone <your-fork>
cd skills

# 2. Create a new skill from the template
cp -r skills/_template skills/my-skill

# 3. Edit SKILL.md
$EDITOR skills/my-skill/SKILL.md

# 4. Validate your skill
./scripts/validate.sh skills/my-skill

# 5. Submit a PR
git add skills/my-skill
git commit -m "feat: add my-skill"
git push origin main
```

## Skill Requirements

### Must Have

- [ ] `SKILL.md` with valid YAML frontmatter (`name` and `description` required)
- [ ] `name` field matches the directory name (lowercase, hyphens, max 64 chars)
- [ ] `description` clearly states what the skill does AND when to use it
- [ ] Instructions are procedural (step-by-step)
- [ ] Total `SKILL.md` body under 500 lines / 5000 tokens

### Should Have

- [ ] `README.md` with human-readable documentation
- [ ] Examples showing sample inputs/outputs
- [ ] Edge case handling
- [ ] Error recovery guidance

### Nice to Have

- [ ] `evals/` directory with test cases
- [ ] `scripts/` with executable helpers
- [ ] `references/` with supplementary docs
- [ ] `metadata` in frontmatter (author, version, tags)

## Writing a Good Description

The description is critical. It is what the agent uses to decide whether to activate your skill. Be specific:

```yaml
# Good: tells the agent WHAT and WHEN
description: >
  Extract text and tables from PDF files, fill PDF forms, and merge
  multiple PDFs. Use when working with PDF documents or when the user
  mentions PDFs, forms, or document extraction.

# Bad: too vague for the agent to match
description: Helps with PDFs.
```

## Writing Good Instructions

The markdown body is loaded into the agent's context when activated. Tips:

1. **Start with "When to Use"** -- reinforce the activation criteria
2. **List prerequisites** -- what tools/packages are needed
3. **Be procedural** -- numbered steps, not prose
4. **Show examples** -- concrete input/output pairs
5. **Handle errors** -- what to do when things go wrong
6. **Keep it concise** -- under 5000 tokens; use `references/` for details

## Directory Structure

```
my-skill/
├── SKILL.md              # Required: metadata + instructions
├── README.md             # Recommended: human docs
├── scripts/              # Optional: executable helpers
│   └── run.sh
├── references/           # Optional: detailed docs
│   └── api-reference.md
├── assets/               # Optional: templates, configs
│   └── template.json
└── evals/                # Optional: test cases
    └── evals.json
```

## Validation

Run the validator before submitting:

```bash
./scripts/validate.sh skills/my-skill
```

This checks:
- `SKILL.md` exists and is parseable
- Required frontmatter fields present
- `name` matches directory name
- Description is not empty
- Body is under token limit

## Evaluation Format

If you include evals, use this format in `evals/evals.json`:

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User prompt that should trigger this skill",
      "expected_output": "Description of expected behavior",
      "assertions": [
        "Output includes X",
        "Agent performed step Y"
      ]
    }
  ]
}
```

## PR Checklist

Before submitting your PR:

- [ ] Skill directory name matches `name` in `SKILL.md`
- [ ] `./scripts/validate.sh skills/my-skill` passes
- [ ] Tested the skill in at least one agent (Claude Code, Cursor, etc.)
- [ ] No sensitive data (API keys, passwords, personal info)
- [ ] License specified if different from repository MIT

## Code of Conduct

Be respectful, constructive, and collaborative. Skills should be useful, well-documented, and safe.

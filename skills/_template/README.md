# _template

Starter template for creating new Agent Skills.

## Usage

```bash
cp -r skills/_template skills/my-new-skill
$EDITOR skills/my-new-skill/SKILL.md
```

Then edit `SKILL.md`:
1. Update the `name` field to match your directory name
2. Write a clear, specific `description`
3. Replace the body with your skill instructions
4. Add scripts, references, and assets as needed

## Structure

```
my-new-skill/
├── SKILL.md          # Required: metadata + instructions
├── README.md         # Recommended: human-readable docs
├── scripts/          # Optional: executable helpers
├── references/       # Optional: supplementary documentation
├── assets/           # Optional: templates, data files
└── evals/            # Optional: test cases
    └── evals.json
```

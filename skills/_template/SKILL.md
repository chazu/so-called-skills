---
name: _template
description: >
  Starter template for creating new Agent Skills. Copy this directory,
  rename it, and edit SKILL.md with your own instructions.
metadata:
  author: template
  version: 0.1.0
  tags:
    - template
    - starter
---

# Skill Name

> Replace this with your skill name and a brief tagline.

## When to Use

Use this skill when:
- The user asks about [specific topic]
- The task involves [specific operation]
- The user mentions [keywords]

## Prerequisites

- [Tool or dependency required]
- [Environment requirement]

## Steps

1. **Assess the situation**
   - Check if [prerequisite] is available
   - Determine [relevant context]

2. **Execute the task**
   - Do [step one]
   - Then [step two]
   - Verify [expected result]

3. **Handle results**
   - If successful: [what to do]
   - If failed: [recovery steps]

## Examples

### Example 1: Basic Usage

**User says:** "Do X with Y"

**Agent does:**
```bash
# Example command or action
echo "example"
```

**Expected result:** Description of what should happen.

### Example 2: Edge Case

**User says:** "Do X but in unusual situation"

**Agent does:** Handle the edge case by...

## Edge Cases

- **Missing dependency**: Check and install, or inform the user
- **Permission denied**: Suggest running with appropriate permissions
- **Empty input**: Gracefully handle and ask for clarification

## References

- See `references/` for detailed documentation
- See `scripts/` for executable helpers

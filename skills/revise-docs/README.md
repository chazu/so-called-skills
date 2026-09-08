# Revise Docs

Review LLM-authored documents by editing them directly, then let the agent turn
your feedback into a polished, committed revision.

1. Invoke `/revise-docs` and name the documents, for example:
   `/revise-docs docs/design.md docs/implementation-plan.md`.
2. The agent checks that the working copy is clean and the documents are
   committed. If there are changes, it asks whether to stash or commit them.
3. Open the documents, add questions or instructions, cut passages, or change
   wording. The entire diff is your feedback; no special markup is required.
   You can optionally prefix a directive with `>>`.
4. Save your edits and tell the agent you're ready. It revises the documents,
   discusses decisions when needed, checks the result, and commits it.

For example, type `What is a lease here?` beside an unclear passage or
`>> Ask an adversarial agent to challenge these failure assumptions.` in a plan.
The agent incorporates the resulting clarification into the document and
removes resolved remarks. It leaves any preparation stash intact and does not
push commits automatically.

Requires Git and an agent that can read and edit the working copy. Independent
adversarial review additionally requires agent delegation. Invocation syntax
depends on the host; the skill's name is `revise-docs`.

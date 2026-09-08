---
name: revise-docs
description: >
  Revises LLM-authored documents through a human review loop, treating the
  entire Git diff from a clean, committed baseline as review annotations.
  Use when the user invokes /revise-docs or wants to annotate one or more
  documents, usually Markdown, for an agent to revise and commit.
metadata:
  author: chazu
  version: 0.1.0
  tags:
    - documentation
    - editing
    - review
license: MIT
compatibility: Requires Git and a working copy containing the documents.
---

# Revise Docs

Turn the user's edits into clear, accurate documents. The committed original
is the baseline; the whole subsequent diff is feedback. No comment syntax is
required. Lines beginning with `>>` optionally make a directive explicit.

## Workflow

1. **Establish the review baseline.** Read the repository's agent instructions
   and identify the target documents from the request or session. Ask for paths
   if they are unclear. Check the entire working copy with
   `git status --porcelain=v1 --untracked-files=all`, including staged changes.
   If dirty, summarize the changes and ask whether the user wants to stash or
   commit them. Carry out their choice; do not choose for them or discard changes.
   A stash must include untracked files when needed, and its identifier must be
   reported. If stashing would remove a target document, explain that it needs
   to be committed to participate in this review. Resolve conflicts or missing
   commits before continuing. Verify that every target exists in `HEAD` and
   that the working copy is clean. Record the repository, branch, full baseline
   commit ID, target paths, and any stash identifier in the session.

2. **Hand over for annotation.** Tell the user the baseline is ready, list the
   documents, and invite them to edit, save, and tell you when finished. Plain
   questions, fragments, deletions, replacements, and moved passages all count;
   `>>` is optional. End the turn and wait for their signal. Do not modify the
   documents or create tracking files in the working copy while they annotate.

3. **Read the complete feedback when the user returns.** Resume this review;
   do not repeat the clean-tree gate or stash/commit their annotations. Read the
   committed originals, current documents, and their full diff against the
   recorded baseline, including staged and unstaged edits. For example,
   `git diff --no-ext-diff --no-textconv <baseline> -- <document-paths>` compares
   the current working files with that commit. Check status for renames,
   deletions, and changes outside the selected documents. If the branch or
   `HEAD` changed, inspect the intervening changes before attributing them to
   the user. Clarify uncertain provenance or newly affected document scope;
   preserve unrelated changes. If the baseline was lost, recover it from the
   session or ask instead of assuming all existing edits are annotations.
   If there is no feedback diff, report that and wait. Preserve a copy of the
   annotation diff outside the working copy before editing, and keep a brief
   inventory of the remarks so none are lost during revision.

4. **Interpret and address every remark.** Treat the entire diff as annotations,
   not just additions or marked lines. Infer whether each change requests an
   explanation, correction, elaboration, restructuring, deletion, or direct
   wording change. Preserve intended direct edits. A question such as "what is
   X?" normally asks for an explanation in the document, not merely a chat
   answer. Read enough surrounding context and relevant source material to
   answer accurately; distinguish proposals from implemented behavior and
   evidence from assumptions. Follow explicit requests for deeper analysis.
   When adversarial agent review is requested and delegation is available,
   give an independent agent the relevant document and a bounded challenge to
   its assumptions, failure modes, and evidence. Assess its findings before
   integrating them; if delegation is unavailable, disclose that and perform
   a critical review yourself without claiming an independent review occurred.
   Revise documents within the requested scope; an implementation-plan remark
   does not itself authorize implementing the plan or publishing anything.

5. **Discuss material ambiguities, then revise.** Use conversation when a remark
   exposes a decision, competing interpretations, or a misconception better
   resolved together. Continue independent revisions while awaiting answers.
   After discussion, put the resulting clarification into the documents where
   useful. Do not silently resolve consequential uncertainty. Keep unresolved
   remarks visible and identify what needs an answer. Once addressed, remove
   annotation text and directive markers that are not intended document content.

6. **Verify and commit the revision.** Reconcile the final documents with every
   remark, including deletions and requests spanning several documents. Check
   clarity, factual support, terminology, links, and consistency across the set;
   run applicable repository documentation checks and `git diff --check`.
   If feedback remains unresolved, report it and finish the discussion before
   the final commit. Inspect status again, stage only the intended document
   revisions, and inspect the staged diff to ensure unrelated changes are not
   included. Commit the finished revision with a descriptive message without
   asking for another approval; this is part of the requested review loop.
   If there is no net change, explain why rather than creating an empty commit.
   Report the revised files, substantive decisions, validation, and commit ID.
   Leave any baseline-preparation stash intact and remind the user of its ID;
   do not restore it or push automatically. For another review round, establish
   a fresh clean baseline at the revised commit.

## Examples of annotation intent

- Added `What does durable mean here?` after a claim: define what survives,
  under which failures, using evidence from the system being described.
- Added `>> Pressure-test this recovery plan with an adversarial agent`:
  obtain the requested review and revise the plan based on supported findings.
- Replaced a paragraph with `Too abstract. Walk through a failed request.`:
  use the original paragraph as context and write a concrete failure walkthrough.
- Deleted a redundant paragraph or directly corrected a term: preserve that
  editorial intent and adjust surrounding transitions or references as needed.

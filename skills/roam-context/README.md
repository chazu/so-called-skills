# Roam Context

Use org-roam as a context store that any agent harness can read, without
letting agents write into your notes.

- **Reads** go straight to the org-roam SQLite database (opened read-only) and
  note files. Emacs does not need to be running.
- **Only opted-in notes are visible.** A note is shared when it carries the
  `agent` tag; everything else is invisible to the CLI, including in search
  results and link listings.
- **Writes go to a staging inbox** outside the org-roam directory, one org file
  per day. Nothing reaches org-roam until you promote it.

## Setup

Requires `bash`, `sqlite3`, and `rg`.

1. Install the skill, for example `./install.sh --skill roam-context --target
   agents --link`.
2. For harnesses without Agent Skills support, put the CLI on your `PATH` and
   mention it in that harness's instructions file (`AGENTS.md` or similar):

   ```bash
   ln -s "$PWD/skills/roam-context/scripts/roam-ctx" ~/.local/bin/roam-ctx
   ```

   ```markdown
   My org-roam notes are available through `roam-ctx` (run `roam-ctx help`).
   Use `roam-ctx index`/`get` for context and `roam-ctx capture` to save
   findings. Never read or write ~/org/roam directly.
   ```

3. Run `roam-ctx status` to confirm the database and inbox paths. Set the
   `ROAM_CTX_*` variables (see `SKILL.md`) if your paths differ.

## Note Conventions

Sharing a note takes one tag; a summary is optional but makes the index far
more useful. Neither changes how the note behaves in org-roam.

```org
:PROPERTIES:
:ID:       1CD70A22-7867-474E-BFC2-02E8F6423E1F
:SUMMARY:  Tartan project hub: goals, architecture, open threads
:END:
#+title: Tartan
#+filetags: :agent:project:
```

- **Share at file level** with `#+filetags: :agent:` so the note is also
  covered by `search`. Tagging a single heading shares only that subtree, which
  can be read but is not searched.
- **Write `:SUMMARY:` to tell notes apart**, not to restate the title. Agents
  choose what to read from the index alone.
- Org-roam picks up tag and property changes when you save the file.

## Captures

Agents write captures with `roam-ctx capture`. Each one arrives tagged and
with a filing recommendation:

```org
* Laya is too weak zero-shot to gate tool calls :agent:repo_skills:owner_chazu:laya:routing:
:PROPERTIES:
:SUMMARY: Laya scores below the majority baseline untuned; fine-tune or use Jev
:FILE_TO: 1CD70A22-7867-474E-BFC2-02E8F6423E1F
:FILE_UNDER: Tooling > Models
:CAPTURED: [2026-10-21 Wed 14:03]
:SOURCE: claude-code
:REPO: github.com/chazu/skills
:BRANCH: main
:COMMIT: 519f0da
:CWD: /Users/chazu/dev/ai/skills
:END:
Scores 0.362 on TypeSafe's benchmark, below the 0.461 majority baseline.

Related: [[id:1CD70A22-7867-474E-BFC2-02E8F6423E1F][Tartan]]
```

- Repository, owner, branch, and commit come from git at the agent's working
  directory. The agent adds keywords, a summary, and links to shared notes.
- `FILE_TO` is `new` or a shared note's id; `FILE_UNDER` is a heading path in
  that note. The CLI rejects ids and paths that do not exist.
- Captures have no `:ID:`, so org-roam never indexes the inbox.

## Daily Triage

> **Reference only.** `emacs/roam-ctx-triage.el` is a reference copy. The
> maintained version lives in the author's private dotfiles repository, and
> updates to this copy are best-effort only, so it may lag behind. Copy it
> into your own config rather than loading it from this repository.

Load the triage mode once in your Emacs config:

```elisp
(add-to-list 'load-path "/path/to/your/copy")
(autoload 'roam-ctx-triage "roam-ctx-triage" nil t)
```

Run `M-x roam-ctx-triage`. It shows one capture at a time, oldest first, with
its summary and recommended destination in the header line:

| Key | Action |
| --- | ------ |
| `f` | File where the agent recommended |
| `F` | File elsewhere: pick a note (a new title makes a new note), then a heading |
| `d` | Discard (kept in `.discarded.org` in the inbox, just in case) |
| `e` | Edit the capture; `C-c C-c` resumes triage |
| `n` / `p` | Next / previous capture |
| `q` | Quit; untriaged captures stay put |

Filing into a new note writes a fresh file in `org-roam-directory` with its
own ID, the capture's tags as `#+filetags`, and its provenance properties.
Filing into an existing note adds a child heading under the recommended
heading, without the share tag, since that note is already shared. Inbox
files are deleted as they empty.

Do not run `org-roam-extract-subtree` on inbox captures: it gives the capture
an ID inside the inbox, and the extracted note then collides with that stale
entry and drops out of the database.

<!-- cl-sync src=5cbf8ac9 -->
# Handoff Creation Procedure

When and how to write a session handoff. A handoff is a single file that lets
a fresh session pick up cold without re-deriving state from git, memory, or
chat history.

Pairs with `procedures/handoff-template.md` (the actual template) and
`procedures/session-kickoff.md` (the reader's procedure).

## When to write a handoff

Write one when ANY of these holds:

- Work spans multiple sessions or multiple days
- State is complex: open PRs across repos, in-flight migrations, partial
  implementations, blocked-on-upstream items
- Bug-bash or incident wrap-up where context will be needed later
- Workstream charter (longer-term initiative with multiple stages)
- Session-end checkpoint regardless of completion — the next session should
  know what's in flight

Skip when:

- The work fully completed in-session and shipped
- Trivial fixes / single-PR work where the PR description carries full context
- Read-only exploration with no follow-up

## Where it goes

`docs/handoffs/YYYY-MM-DD-HANDOFF-<author>-<topic>.md` (e.g.,
`docs/handoffs/2026-05-09-HANDOFF-owenjohnson-shepherd-system.md`).

A baton's identity is **author + topic**. `<author>` is your GitHub login
(resolve it with `gh api user --jq .login`), lowercased in the filename;
`<topic>` is a kebab-case slug of the workstream. The author segment keeps
two different people working the same repo from colliding on a same-day
handoff; the topic segment keeps two concurrent sessions by the same person
from colliding. The filename exists for uniqueness, date-sort, and
glance-ability — it is not unambiguously re-splittable (author and topic are
both hyphenated slugs), so the authoritative values live in frontmatter:
`author:` is the exact gh login (machine-filterable), `author_name:` is the
optional human/descriptive string. See toolkit ADR-002
(`centient-labs/toolkit docs/adr/ADR-002-per-author-handoff-batons.md`) for
why identity is author-keyed and why the earlier "seat" abstraction was
rejected.

**Never adopt a foreign baton.** Surfacing and resume filter to the viewer's
own gh login. A baton authored by someone else stays visible as an open
handoff issue, but another author's session must never auto-resume it or
close it, and a foreign `auto_resume: true` is never honored — it is a
signal to that author's next session, not to yours.

**Date-first, then the uppercase type token, then the author and topic
slugs** (`<date>-<TYPE>-<author>-<topic>.md`). Date-first makes a directory
of mixed dated docs (handoffs, audits, retros) sort chronologically in one
listing; a type-first name only sorts within its own prefix. Back-compat:
legacy topic-only filenames (`YYYY-MM-DD-HANDOFF-<topic>.md`) and batons
with missing-author frontmatter remain valid and surface to everyone —
existing batons never become invisible, and there is no flag-day. Legacy
`HANDOFF-YYYY-MM-DD-topic.md` files also remain readable (the kickoff
procedure normalizes both forms when sorting) — `git mv` them to date-first
when you next touch them.

For workspace-meta repos without a `docs/` directory, a top-level `HANDOFF.md`
is acceptable as a current-snapshot file — but rotate to `docs/handoffs/`
when the directory is created.

## What it must contain

Minimum sections (see `handoff-template.md` for the fillable structure):

1. **Priority for next session** — 1-3 specific actions, in order
2. **What was accomplished** — concrete, with PR links / file paths / metrics
3. **Open follow-ups** — known unfinished items with current state
4. **Operational notes** — commands, paths, credential references (vault
   entry names, keychain entries, or env var names — never actual secret
   values) the next session will need
5. **Hard guardrails** — anything the next session must not do, and why

## How to write one

1. Copy the template (creating `docs/handoffs/` if needed). Set the
   `topic` shell variable to a kebab-case slug of the workstream; the
   snippet resolves your gh login as `author` and interpolates both into
   the destination filename. The `gh` lookup itself is non-fatal (`|| true`
   inside the substitution), so even under `set -euo pipefail` a failed
   lookup reaches the empty-`author` guard, which aborts the subshell
   with the specific remediation message; the sentinel default
   refuses to proceed if you forget to edit `topic`, and an explicit
   existence check refuses to overwrite a same-day handoff for the same
   author + topic (re-run with a different topic if you hit that case).
   The whole block is wrapped in `( ... )` so the `exit 1` aborts
   only this subshell — never your interactive shell — even if you
   paste the snippet into a working terminal. The trailing `|| { ... }`
   surfaces subshell failure loudly so you do not silently advance to
   the next step on a failed copy.
   ```bash
   (
     topic=REPLACE_ME    # <-- EDIT THIS to your kebab-case slug
     if [ "$topic" = REPLACE_ME ] || [ -z "$topic" ]; then
       echo "edit topic= to a kebab-case slug first" >&2
       exit 1
     fi
     author=$({ gh api user --jq .login 2>/dev/null || true; } | tr '[:upper:]' '[:lower:]')
     if [ -z "$author" ]; then
       echo "could not resolve gh login (gh api user --jq .login) — authenticate gh first" >&2
       exit 1
     fi
     dest="docs/handoffs/$(date +%Y-%m-%d)-HANDOFF-${author}-${topic}.md"
     if [ -e "$dest" ]; then
       echo "$dest already exists — choose a different topic slug" >&2
       exit 1
     fi
     mkdir -p docs/handoffs && \
       set -C && cat .agent/procedures/handoff-template.md > "$dest"
   ) || { echo "handoff creation aborted — fix the issue above and re-run" >&2; false; }
   ```
   The `[ -e "$dest" ]` existence check refuses with a clear message
   if a same-day handoff for the same author + topic already exists; re-run
   with a different `topic` if you hit that case. The creation step
   itself is also no-clobber — `set -C` (noclobber, scoped to the
   subshell) makes the `>` redirection fail if `$dest` appears
   between the check and the write, so even that race cannot
   overwrite an existing handoff.
   (Previously this snippet used `cp -n` for the guard, but `cp -n`
   silently exits 0 on macOS/Linux when the destination exists,
   which would let the procedure start editing the wrong file.)
2. **Fill the YAML frontmatter completely.** It is the machine-readable
   contract: session-start hooks and `/cl-resume-session` parse it instead
   of the prose. `engram_session` is the exact `sessionId` this session
   passed to `start_session_coordination` (so the next session can
   `load_session` deterministically); `handoff_issue` is back-filled after
   the handoff issue is created; use `null` — never a blank — for fields
   that don't apply.
3. Fill in sections top-to-bottom. The template marks each section
   **(required)** or **(optional)**:
   - **Required sections** (the minimum-section set above) must remain
     in the file. If a required section has nothing real to say, write
     a one-line `n/a — <reason>` rather than deleting the heading.
   - **Optional sections** can be deleted cleanly when they don't apply.
     Empty optional sections rot; either fill them or remove them.
4. Cite specific PRs / issues / commits with **full URLs**. Handoffs are
   read in fresh contexts where short refs are ambiguous.
5. **Convert relative dates to absolute.** "Thursday" → "2026-05-15."
   Handoffs outlive their relative time references.

## Anti-patterns

- **"We'll figure it out" sections.** If you don't know, say
  "Open question: X" with the question framed.
- **Vague pointers.** "Check the auth code" → "Check
  `src/auth/token-provider.ts:142` — the token cache TTL handling."
- **Relative time references.** "Yesterday" / "next week" → absolute dates.
- **Copy-paste from chat.** Synthesize. The handoff is a contract, not a
  transcript.
- **Burying decisions.** Open questions and pending decisions go in their
  own section, not inline in narrative prose.

Repo-specific additions: see `handoff-creation-local.md` (loaded alongside this file).

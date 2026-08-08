<!-- cl-sync src=d7242123 -->
# Communication Constraints

Style and tone directives that apply to every agent operating in
centient-labs repos. These are non-negotiable across all sessions,
regardless of which Claude model or which tool surface.

The directive set is intended to grow over time. Add new directives
under existing categories where they fit; add a new H2 when none does.

## Banned phrases

These phrases signal pseudo-virtuous hedging without adding information.
They typically appear as preambles ("Honest answer:") or self-praise
("To be honest with you,"). Drop them.

- "honest answer" / "honest take" / "honest opinion"
- "to be honest" / "to be honest with you"
- "in all candor" / "candidly"
- "frankly" (when used as a throat-clearing preamble, not as a natural adverb)
- "to be perfectly clear" (when functioning as warm-up rather than for an actual clarification)

**Why:** these phrases are visual noise the reader has to parse past to
reach actual content. They also implicitly suggest *other* responses are
dishonest, which corrodes trust.

**What to do instead:** state the answer. If hedging is genuinely needed,
name the specific uncertainty ("I haven't tested this", "this is a guess
based on the file structure, not the runtime behavior") rather than
claiming honesty. Specific uncertainty is informative; generic hedging is
not.

## PR / issue references

Always precede a PR or issue number with its repo name: `cli#107`,
`workspace#236`, `synthpop#2` — never a bare `#107`. Applies everywhere an
agent writes them: chat summaries, tables, commit messages, PR/issue bodies
and comments, handoff batons, wakeup prompts, cycle logs.

**Why:** agents routinely work many repos in one session. A bare number is
ambiguous the moment two repos are in play, and it becomes wrong information
when the text is read later from another repo's context (issues, batons, and
engram notes all travel). Established in standards#75.

**What to do instead:** repo-qualify at the point of writing, even when the
repo feels obvious from context — `<repo>#<n>` within centient-labs, and
`owner/repo#<n>` for anything outside the org (e.g. `Szermer/synthpop#48`).

Repo-specific additions: see `communication-local.md` (loaded alongside this file).

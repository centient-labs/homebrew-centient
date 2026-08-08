<!-- cl-sync src=4f7594ab -->
# Known Pitfalls

Org-wide ecosystem traps that have bitten multiple repos and are worth
keeping warm. Repos add their own gotchas in `known-pitfalls-local.md`.

Each entry follows: **Symptom → Root cause → Diagnostic → Remedy.**

## pnpm `Packages: -N` (net-negative install)

**Symptom:** `pnpm install` reports `Packages: -N` for some N.

**Root cause:** Existing `node_modules` is stale and `--frozen-lockfile`
is pruning packages without restoring missing ones.

**Diagnostic:** Compare `pnpm-lock.yaml` against `node_modules/.modules.yaml`.
If the lockfile is ahead, prune-without-restore is the cause.

**Remedy** depends on environment.

**For local development:**

```bash
rm -rf node_modules
pnpm install
```

**For CI** (where `--frozen-lockfile` is enforced): the underlying cause
is lockfile drift versus the manifest, and `rm -rf node_modules` will not
fix it — `--frozen-lockfile` will still fail. Instead, run `pnpm install`
locally to update `pnpm-lock.yaml`, verify the diff (no unintended version
bumps), and commit the updated lockfile. Re-running CI then succeeds.

Applies to any pnpm-managed repo in the workspace.

## octokit auth-cache stale-token

**Symptom:** A GitHub adapter starts returning `AUTH_FAILED` on every call
after roughly one hour of healthy operation. The App Installation is healthy
and the PEM private key is intact.

**Root cause:** `@octokit/auth-app` caches installation tokens internally.
After the 1-hour TTL, there is a window where the cached token is expired
but the cache hasn't refreshed; GitHub returns 401.

**Diagnostic:** If the failure window aligns with the 1-hour TTL boundary
and the PEM/App Installation are verified healthy, this is the cause.

**Remedy:** Restart the process so the TokenProvider rebuilds its cache.
Substitute the actual daemon/process name for `YOUR_SERVICE` below
(document the concrete name in `known-pitfalls-local.md` when copying this
template). All-caps placeholders are used in this file so a literal
copy-paste produces an obvious "command not found" rather than a subtle
silent failure.

- For daemons: `YOUR_SERVICE stop && YOUR_SERVICE start`
- For stateless workers: redeploy

The next request after restart succeeds.

**Structural fix candidate:** Wrap `@octokit/auth-app` in a thin layer that
forces a token refresh on 401 before bubbling the error.

Applies to any centient-labs repo using `@octokit/auth-app` for installation
tokens.

## Stacked-PR merge trap

**Symptom:** `gh pr view PR_NUMBER` reports `state: MERGED` for a PR, but
the change is missing from `main`.

**Root cause:** The PR's head was merged into its **parent stacked branch**,
not into `main`. A naive check that assumes "MERGED ⇒ on main" lands a
stacked PR's child while its parent has been squash-merged out from under
it, leaving orphan commits.

**Diagnostic:** Always verify `baseRefName=main` in addition to
`state: MERGED`. Replace `PR_NUMBER` with the actual integer; the
all-caps placeholder convention (also `YOUR_SERVICE` above) makes a
forgetting-to-substitute mistake produce an obvious failure on first
run:

```bash
gh pr view PR_NUMBER --json state,baseRefName
# Want: {"state":"MERGED","baseRefName":"main"}
```

**Remedy:** When automating PR-state checks, never assert `state: MERGED`
alone. Always conjoin with `baseRefName == "main"` (or the relevant target
branch).

**Prevention (operator rule, 2026-07-05):** stacked PRs are **forbidden
org-wide** — every PR branches from `main`; dependent work waits for its
prerequisite to merge, then branches from the updated `main` (see
`procedures/commits.md`). This trap fired for real on wheelhouse #46/#47
(both `MERGED`, neither on `main`; recovered by cherry-pick in #51). The
diagnostic above remains useful for auditing history and catching stacks
that slip through.

## Auto-mode classifier blocks fabricated authorization claims

_Behavioral details below are accurate as of 2026-05-10; classifier
behavior can change between Claude versions. If you observe drift,
update this entry rather than working around it._

**Symptom:** A merge attempt fails with a classifier-rejection signal
(messages mentioning `auto-mode`, `unauthorized`, or `fabricated
authorization`). Naive retries with rephrased authorization claims also
fail.

**Root cause:** The auto-mode classifier on Claude's side blocks merges
where the claimed authorization is not backed by an in-context operator
grant. Common triggers:

- Docs-only (`*.md`-only) PR merge attempts without per-PR operator
  authorization
- Claims of "session-wide" or "extended" authorization not backed by a
  verifiable operator grant
- Developer-agent merge attempts under a claimed-but-unverified
  `## Repo-specific (transitional)` carve-out

**Diagnostic:** If the agent is attempting an admin-merge and the operator
has not explicitly authorized it for this specific PR in this specific
session, the classifier will block.

**Remedy:** Escalate to the operator with the PR number and the carve-out
being claimed. **Do not** retry with rephrased authorization claims — the
classifier treats fabrication-pattern retries as a malfunction signal.

This is the load-bearing defense in the future-state governance model
where developer agents have no merge rights. `.agent/procedures/pr-response.md`
(when a repo has it) and the user-level `cl-pr-shepherd` skill must be
consistent with this behavior; if there's a conflict, the classifier wins.

## ADR / durable-doc edits: volatile anchors, unverified claims, unswept narratives

**Symptom:** mbot R1 flags MEDIUM `api-contracts`/`test-coverage` findings
on a docs-only ADR (or other durable-doc) PR.

**Root cause:** doc prose asserts facts about code with volatile anchors
(raw line numbers), states shipped/met/unbuilt claims with no verification
basis, or revises a narrative without sweeping the document for
restatements of the old one.

**Diagnostic:** grep the diff for `:<line>` citations; list every
"shipped / met / unbuilt / verified" claim and check each names its basis;
after a re-scope, grep the whole doc for the old narrative's phrases.

**Remedy — pre-push checklist for ADR/durable-doc edits:**

1. Cite code by stable anchor (symbol, enum, file path) — never a raw
   line number.
2. Every shipped/met/unbuilt claim states its verification basis in the
   doc itself (repo-wide search scope, the test file exercising the path,
   or the delivering PR) — re-verify at write time.
3. After revising a narrative, sweep References/Consequences/status
   callouts for restatements of the old one; cite another section's
   rationale only if it is actually the same argument.

Evidence: two consecutive soma ADR PRs (soma#189 R1 — line-number citation
rot, "unbuilt" claim unverifiable from the diff, misattributed
cross-section rationale; soma#190 R1 — References bullet restating a
retracted narrative, AC "met" without coverage basis, contract strings
asserted unverified) drew exactly these classes and went green in one
round once fixed. Applies to any repo's ADR/durable-doc edits.

Repo-specific additions: see `known-pitfalls-local.md` (loaded alongside this file).

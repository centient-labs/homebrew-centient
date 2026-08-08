<!-- cl-sync src=fc9c663d -->
# Lane Discipline (cross-repo work)

**Your lane is this repo.** A developer seat works the repo it was launched
in — its issues, its PRs, its branches. Work you identify in *another* repo
is a handoff, not a takeover.

## The rule

When you find work that belongs to another repo (a bug, a missing feature, a
contract change you depend on):

1. **File an issue on that repo** — `gh issue create -R centient-labs/<repo>`,
   label `cross-repo-request`, with enough context to be actionable without
   you: file refs, repro, the consuming use case, a suggested fix if you have
   one.
2. **And/or send a comms message** to that repo's seat (engram-comms) so it
   wakes and picks the issue up.
3. **Do NOT** clone, branch, edit, or open a PR against the other repo —
   unless the operator explicitly authorized it *this session*. A standing
   task ("fix X here") is never implicit authorization to also patch its
   dependency.

Always fine, no authorization needed: **reading** other repos, and
**commenting** on their issues and PRs (including rationale replies).

## Why

- Two seats editing one repo concurrently produce conflicting PRs, duplicated
  effort, and worktree/branch collisions — failure modes that multiply with
  the number of seats.
- The owning seat carries context you don't have (its ADRs, in-flight
  branches, review history). A drive-by PR that ignores an in-flight design
  costs more review time than the issue would have.
- Provenance: all seats share one GitHub login, so an out-of-lane PR is
  indistinguishable from the owning seat's work in the audit trail.

## Exceptions

- **A committed grant**: a `granted` entry in the target repo's own
  `.agent/seats.json` puts you in lane there. No seat is exempt by role — the
  coordinator / workspace seat is org-wide because the operator granted it in
  every repo, not because of its role.
- **Operator authorization**: explicit, per-session, per-repo. Name it in the
  PR body when used ("cross-repo authorized by operator, <date>"). There is no
  env override — the `CL_LANE_SCOPE` / `CL_CROSS_REPO_OK` hatches are retired
  (standards#85); recovery is an operator-granted `seats.json` entry via
  reviewed PR.

## PR provenance

Every PR body carries its originating lane: `Seat: <repo>`. Tooling that
files PRs for you stamps this automatically; add it manually otherwise.

Repo-specific additions: see `lane-discipline-local.md` (loaded alongside this file).

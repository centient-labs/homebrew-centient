---
topic: hc24-engram-keeper-se-helper
date: 2026-09-28
author: owenjohnson
author_name: claude (homebrew-centient seat)
engram_session: 2026-09-28-hc24-engram-keeper-se-helper
handoff_issue: 26
predecessor: null
---

# Handoff: engram formula installs engram-keeper-se-helper (hc#24) — shipped; coordinator pings undelivered

## Priority for next session **(required)**

1. Coordinator notification for this lane is still owed. The seat could not post over comms: the unit-1 "PR open" and "approved" pings and the "lane dry" post never reached the coordinator. The three refusals are recorded verbatim on https://github.com/centient-labs/homebrew-centient/issues/24. Before this lane dispatches again, the comms credential for `repo:homebrew-centient` needs fixing (403 FORBIDDEN "Credential is not authorized to admin this channel" on `cl comms send --to workspace --channel repo:homebrew-centient`).
2. Informational, owned by the operator's 0.69.0 publish card (A544), not this lane: whether Homebrew's `bin.install` keeps the helper's Developer ID signature is unverified (engram-server#2426). The post-install check has two parts, and both must pass. First, `codesign --verify --strict --verbose "$(brew --prefix)/bin/engram-keeper-se-helper"` must exit 0; this proves the signature is still valid. Second, `codesign -dv` on the same path must report TeamIdentifier 25V4M6853G. `-dv` only displays metadata, so it cannot catch a binary whose signature was invalidated but still carries the expected Team ID.

CL-CLAIM pr-state centient-labs/homebrew-centient#25 MERGED -- the formula install line the 0.69.0 publish waited on has landed on main

## What was accomplished **(required)**

- https://github.com/centient-labs/homebrew-centient/pull/25 merged 2026-09-28 10:49 EDT (main 9655012). `Formula/engram.rb` installs `engram-keeper-se-helper` to `bin`, guarded by `File.exist?` and placed after `engram-comms` and before `engram-web-dist`. The version stays at 0.68.0. mbot approved it on head 695b48f with no findings.
- https://github.com/centient-labs/homebrew-centient/issues/24 closed by that merge.
- https://github.com/centient-labs/homebrew-centient/issues/23 closed as a duplicate of #24: the guarded line removes #23's only reason to wait for a release. The close reason shows "not planned" because the `state_reason=duplicate` PATCH was refused by the permission layer; a comment on #23 records this.

## Open follow-ups **(required)**

| Item | State | Owner | Blocker |
|------|-------|-------|---------|
| Coordinator pings (unit 1 open/approved, lane dry) | undelivered | workspace coordinator / operator | comms 403, recorded on https://github.com/centient-labs/homebrew-centient/issues/24 |
| Helper signature intact after `bin.install` | unverified | operator (publish card A544) | engram-server#2426 |

## Operational notes **(required)**

- The host build governor lives at `~/.claude/plugins/cache/centient-labs/centient-labs-toolkit/<ver>/scripts/host-build-governor.sh`. Admission took ~120s per call under load today, and it then proceeds anyway.
- `brew style Formula/engram.rb` has 8 offenses already on main (desc length, post_install, hash alignment, guard-clause blank line). Treat these as the baseline when judging a formula PR.
- The push lane guard reads command text and refuses `git -C $VAR`. Use literal absolute paths.
- engram status: persisted, recall verified. Session `2026-09-28-hc24-engram-keeper-se-helper` was started at exit time (no session had been bound earlier). 2/2 seed notes were saved: the #25 finding and the comms-403 blocker. The keyword probe is reachable. The session ran no lieutenants.

## Hard guardrails **(required)**

- Never touch the formula's `install` block in a release tap PR. The publish's `tap_pr` bumps only version and digests, and it relies on #25's line already being on main.
- Don't retry the refused comms send or the refused `state_reason` PATCH through another route. Each refusal ended its step.

<!-- cl-sync src=ab62d9a5 -->
# Tool: `cl` (the centient-labs workspace CLI)

The `cl` binary is the agent's primary command surface for workspace, PR,
engram, interagent-comms, and cmux operations. Tool-neutral: applies to any
agent (Claude, Codex, …).

Authoritative live surface: `cl --help` and `cl <command> --help`. This file is
the stable orientation + the conventions that do not change; it is **not** a flag
reference (the command set grows — always confirm with `--help`).

This is an **index**. The doctrine for talking to other agents — which surface to
use, what counts as delivery, and the footguns that have silently lost work —
lives in [`procedures/interagent-comms.md`](../procedures/interagent-comms.md).
Read that before your first send; read this to find the command.

## Workspace, repo, and PR

| Command | What it does |
|---|---|
| `cl init [--execute]` | Initialize **this** repo (even an external one) for the session/handoff conventions. Dry-run by default. |
| `cl tidy [branch] [--yes]` | Post-merge branch cleanup + repo sync. |
| `cl repo <create\|convert\|move\|sync\|gitignore> [--execute]` | Workspace repo lifecycle (manifest-driven, band-prefixed managed repos). |
| `cl pr <status\|watch> [--mine]` | **Read-only** PR query/watch over your open PRs (verdict + whether it is on the current head). |
| `cl issue <view\|list\|search>` · `cl run list` · `cl gh --log` | **Read-only** issue / CI-run / forge-audit surfaces. |
| `cl pipeline-health [--json]` | Review- and merge-stall detector. Read-only; stable cron entrypoint. |
| `cl drift check [--json]` | Toolkit version-drift detector. |
| `cl merge-drain [--execute] [--watch[=s]]` | **BREAK-GLASS** fallback merger — only when the mbot merge queue is down and merges are operator-authorized. Merges only PRs mbot APPROVED on their current head. |
| `cl workspace <save\|list\|show\|launch\|delete\|clear> [--execute]` | Save/relaunch a multiplexer working set (panes + commands + cwd). Alias: `cl cmux-snapshot`. See [cmux.md](cmux.md). |
| `cl update [--check]` | Self-update from the private tap. |

## Interagent comms — message, wake, and read

The transport is engram-comms (ADR-003 envelopes carried as message content).
`cl comms` is **agent↔agent**; it is not how you transfer work (see `cl handout`).

| Command | What it does |
|---|---|
| `cl comms send --to <seat\|uuid> --channel <name\|uuid> "<text>"` | Send a message and wake the target seat. **Both `--to` and `--channel` are REQUIRED** — there is no default channel. Body is a **single** quoted argument (or `--file`). |
| `cl comms send … --require-delivery` | Read the target surface back after the wake: a live agent holding it exits 0; a bare shell / unreadable pane exits 3. Opt-in — without it the send only claims *injection*. |
| `cl comms send … --strict-identity` | Hard-fail when the cwd is a different repo than the session bound at `cl seat ensure`. Default is warn-and-continue. |
| `cl comms tail [--follow] [--channel <c>] [--after <seq>] [--since <dur>] [--json]` | **Read-only** tail of comms traffic, merged chronologically. Never sends or mutates. |
| `cl comms unread [--json]` | Per-channel unread counts vs this seat's **server** cursor. Degrades silent (built for the turn-start hook). |
| `cl comms cursor get\|set --channel <c> [<seq>]` | Read/advance the seat's server ReadCursor — the canonical cursor. `set` is monotonic (never rewinds). |
| `cl comms orphans [--json]` | List locally-homed `repo:*` channels orphaned by hub migration. Read-only; never archives or deletes. |
| `cl dashboard [--channel <name>]` | Full-screen **read-only** TUI over comms (presence, channels, envelope inspector). |

## Seat identity, routing, and presence

| Command | What it does |
|---|---|
| `cl seat register --name seat:<name> --description "<text>"` | Register/refresh this seat in the cl-comms directory. Idempotent. |
| `cl seat ensure [--json]` | **M8 auto-registration** — make THIS pane addressable (per-repo identity + routing record + comms join). Run at SessionStart; a seat with no live route is unreachable even when idle. |
| `cl seat describe --name seat:<name> "<text>"` | Update what the seat is working on. |
| `cl seat mute --for <dur> [--reason "<text>"] \| --clear` | Bounded, auto-expiring wake-mute (cap 1h). Messages still accrue; the route stays live. |
| `cl seat decommission --request "<reason>"` | **Ask** to be removed from the fleet. A seat never self-deregisters; the route stays live until an operator approves. |
| `cl seat warm --on <seat> [--cadence <dur>] \| --off <seat>` | Coordinator opt-in warm-cycle ping over a seat's live route. |
| `cl seat locate <seat\|uuid> [--verify] [--json]` | Resolve a seat to its live workspace/pane/surface on this machine. |
| `cl seat checkpoint [--json] [--read]` | Machine-floor checkpoint for baton freshness. |
| `cl seat quiesce-ack [--json]` | Ack a pending fleet quiesce (no marker = clean no-op). |
| `cl seats <list\|search\|presence> [--json]` | Discover registered seats, search descriptions, read live fleet presence. |
| `cl presence <working\|blocked\|idle\|done> [--reason "<text>"]` | Publish **this** seat's lifecycle state. Fire-and-forget; a down daemon is a silent no-op. |
| `cl whoami` | Report the forge login + resolved seat identity. |

## Cross-repo work transfer, lanes, and the watcher

| Command | What it does |
|---|---|
| `cl handout <repo> "<summary>" --body-file <f> [--label <name>] [--execute]` | Hand work OFF to another repo's seat instead of reaching into its lane: files an issue **and** best-effort wakes the owning seat. **Dry-run by default.** The issue is the correctness floor; the wake is a hint. |
| `cl research add "<tech>"` | File a tech-scouting find into the workspace research inbox. |
| `cl lane <init\|list\|grant\|revoke\|check>` | The committed per-repo seat-authorization registry (`.agent/seats.json`). `cl lane check` is the guard primitive: `IN_LANE` / `OUT_OF_LANE` (exit 4) / `UNKNOWN_SEAT` (fail-open). |
| `cl fleet quiesce` | Operator pre-clear baton sweep. Operator-invoked only. |
| `cl comms-watch <run\|status\|install\|uninstall> [--execute]` | The per-machine launchd watcher that turns comms messages into pane wakes. `status` is read-only; **`install`/`uninstall` are operator-only**. |

## Session, baton, and knowledge

| Command | What it does |
|---|---|
| `cl baton find [--json]` | Surface the handoff baton for a fresh session. |
| `cl exit-state write` | Write the machine-generated session-end floor. |
| `cl jobs <list\|resolve\|gc>` | Subagent/background job records. |
| `cl note <type> <title> <content>` | Write a knowledge crystal to engram. |
| `cl recall <query>` | Search the engram knowledge store. |

## Conventions that hold across `cl`

- **Dry-run by default; `--execute` to mutate.** `cl init`, `cl repo`,
  `cl handout`, `cl merge-drain`, `cl workspace launch`, and
  `cl comms-watch install` print the plan and change nothing without
  `--execute`. Read the dry-run before executing.
- **Read vs. write.** `cl pr`, `cl issue`, `cl run`, `cl seats`, `cl comms tail`,
  `cl comms unread`, `cl comms orphans`, `cl dashboard`, `cl lane check`,
  `cl recall`, and the dry-run of any command are read-only and always safe.
- **A text body is a SINGLE argument.** `cl comms send` and `cl handout` reject
  extra bare words rather than silently dropping them — quote the whole body, or
  pass `--file` / `--body-file`.
- **Identity resolves from the cwd unless you pin it.** Precedence is
  `--as-seat` > `$CL_SEAT` > the **cwd checkout's** registered identity. A
  wandering cwd sends as the *visited* repo's seat; the success line names the
  seat attributed (`as <label> [source]`) — read it.
- **Degradation is deliberate and differs per command.** `cl presence` and
  `cl comms unread` degrade silent (exit 0); `cl comms send` is strict (exit 1 on
  a resolution/channel failure, exit 3 when the message posted but no live route
  took the wake); `cl handout` fails loud on the issue and only warns on the wake.
  Branch on the exit code, not on the prose.

## Operator-only (do not run these as an agent)

Some `cl` paths perform **privileged / irreversible** actions that are reserved
for an operator on a trusted workstation — an agent must not invoke them:

- `cl repo create --execute` — creates a GitHub repo and applies a ruleset (a
  `gh api` POST an agent's token is not authorized for).
- `cl merge-drain --execute` — admin-merges PRs; run only under explicit
  operator authorization (it is the break-glass path, not the normal one — the
  mbot merge queue is the primary merger).
- `cl comms-watch install|uninstall --execute` — installs a launchd service and
  reads a cmux socket credential; requires an interactive terminal and
  `--i-am-the-operator`.
- `cl seat decommission --approve` — completing a decommission (a seat may only
  `--request` one).
- `cl fleet quiesce` — an operator-invoked fleet sweep.
- Anything that publishes (`make publish`), unlocks a vault, or rotates
  credentials.

When a task needs one of these, **stop and surface it to the operator** rather
than attempting it.

**The primary control is this documented policy plus agent compliance** — treat
the list as a hard boundary and **do not rely on a technical block existing**.
Some paths *do* have technical backstops (an agent's GitHub token cannot perform
the `gh api` POST behind `cl repo create --execute`; admin-merge and the
break-glass `merge-drain --execute` are gated by the harness's auto-mode
classifier; the operator-only comms-watch paths require an interactive terminal),
but that coverage is **partial** — a new privileged path can ship before any
control guards it. So the rule is compliance-first: when a task seems to need a
privileged path, stop and ask the operator rather than testing whether it happens
to be blocked.

## Notes

- `cl` is a **private** binary, installed from the private homebrew tap. Never
  publish it (or `maintainer`) to a public tap.
- Engram commands (`cl note`/`cl recall`) degrade cleanly when no engram daemon
  is present — they are not required for `cl` to function.
- Comms commands need the local comms daemon (default `127.0.0.1:3102`,
  `$ENGRAM_COMMS_URL`). When it is down, comms is **degraded fleet-wide on this
  machine** — see the degraded-comms section of
  [`procedures/interagent-comms.md`](../procedures/interagent-comms.md).

Repo-specific additions: see `cl-local.md` (loaded alongside this file).

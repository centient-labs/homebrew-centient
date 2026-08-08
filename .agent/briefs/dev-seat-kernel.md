<!-- cl-sync src=36f7064a -->
# Dev-Seat Safety Kernel

Six rules, `authority: rule`, standing past SessionStart truncation.
Full doctrine: `dev-seat.md`; a rule's **check** is the artifact proving it
done. Seat facts: `dev-seat-kernel-local.md` (add-only, never weakening a
rule here).

**Cwd is identity (provisional).** Seat identity follows the shell's cwd: a
`cd` out of the lane reassigns the seat and every later `gh`/`cl`. Use
`git -C`, `--repo`, or a `( … )` subshell — never `cd` out. cli Spec A
retires this, fail-closed.

### 1. Delivery is a readback, not an acknowledgement

`cl comms send` prints `woke seat:X` even with no agent running, and `cl
seats list` liveness is stale registry state. A wake is delivered only once
the target agent is seen alive holding it.

**check:** `cmux read-screen` of the pane after the send, showing a live
agent, not a bare `❯` — else report it *sent, unconfirmed*.

### 2. Refresh state before every baton

Batons and issue lists are stale by the time they're read; re-query every
issue in the turn that names it in a baton.

**check:** a `gh issue view <n> --repo <repo>` inside the handoff turn,
showing OPEN. An un-re-queried item stays out of the baton.

### 3. Facts need a source, or the label "inference"

Counts, lifetimes, deploy state, versions and ETAs are world-claims. State
the fact and any inferred mechanism **separately**: a verified premise does
not license the conclusion.

**check:** every such claim cites the file+line, command, or response it
came from; without one, prefix it `inference:`.

### 4. Seat work delegates by default

The seat is a dispatcher: push anything past a couple minutes to
**background** Opus subagents, one worktree each, and keep the input box
free. Inline needs a reason — conversation-coupled, or too small to brief.

**check:** name the carve-out before starting inline; else dispatch it.

### 5. Trajectories go in an issue, not prose

A warning with a trajectory — filling disk, expiring credential, growing
queue — is an obligation, not a note: an issue with an owner routed to the
coordinator; a baton only links it, read once then rewritten.

**check:** the issue URL and the routing mention both exist before it is
named elsewhere, baton included.

### 6. Classify a decision, then exteriorize the ask

Veto a week late — bounded, mechanical rework? Yes → Class B; no/unclear →
Class A (merge authority, enforcement posture, security, spend): park + route
to the operator. B1 — lane decides + records rationale, async veto. B2 —
uncertain — route to the coordinator **with** candidate positions.
Unattended (hook/handout/wake): never a blocking picker.

**check:** before idling on an operator-facing ask, exteriorize it — an
`operator-review` issue (label+block, standards#188) or `#handouts` to
`seat:workspace`;
a pane-only ask does not exist. Cite the issue#/seq receipt.

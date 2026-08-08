<!-- cl-sync src=a6cf53a1 -->
# Security Constraints

Principles: P15 (Secure by Default), P16 (Authority Outside the Sandbox)

## Trust Boundary

Derived from **P16 (Authority Outside the Sandbox)** in `DESIGN-PHILOSOPHY.md`.
This rule applies to any component that executes untrusted input. A repo that
runs untrusted input adds its concrete instantiation (which process is the
sandbox, which credentials are at stake, where the protected domain lives)
in `security-local.md`; a repo that never executes untrusted input inherits
the principle without an instantiation.

**The sandbox is whatever executes untrusted input.** An input is untrusted —
wherever it can trigger tools or privileged/irreversible actions — when either
clause holds (standards#25 ruling, 2026-07-18): **(a) provenance** — it is, or
derives from, data that crossed the trust boundary (anything an external party
can influence), however deterministic the processing; or **(b) unverifiability**
— it is generative/agentic model output, regardless of the provenance of the
model's inputs. Examples (illustrative, not a closed list): PR- or
agent-authored code (build scripts, tests, package hooks), LLM output that can
trigger tools or privileged actions, and data/control inputs that can cause
execution or mutation: MCP tool arguments, webhook payloads, deserialized
artifacts, workflow/config files, package metadata, and template-expansion
inputs. Determinism is orthogonal to trust — a temperature-0 model replay and
a deterministically-parsed webhook payload are both untrusted; trusted
randomness makes nothing untrusted.
Isolation (containers, VMs) protects the host *from* that code; it does **not**
protect secrets *co-resident with* it. Absent a separately enforced
intra-sandbox boundary (a sidecar secret broker in a distinct isolation
context, a distinct UID/namespace, one-shot brokered credentials, nested
sandboxing), assume anything inside the sandbox is reachable by the untrusted
input it processes — including read-only-mounted secrets and any scoped token
(assume a token is exfiltratable the moment it enters the sandbox). The trust
question is never "is this in-sandbox process trustworthy?" but "what else
shares the sandbox?"

Therefore:

- **High-value credentials** — long-lived, cross-repo, able to mint other
  credentials, write a protected branch, sign commits, deploy/release/publish,
  or persist governance state — live in a **protected trust domain that never
  executes untrusted input** (a host process, a sidecar broker, a separate
  runner). Never in the sandbox.
- **Privileged, irreversible actions** — commit signing, merge to a protected
  branch, deploy/release/publish, governance-state mutation — execute in that
  protected domain, not the sandbox.
- **Sandboxed components receive only** low-authority, scoped, short-lived,
  revocable tokens — and because even those are assumed exfiltratable, the
  token itself must not grant a privileged action.

**"Protected" is a positive requirement, not just "outside the sandbox."** The
protected domain is separately isolated from the sandbox's filesystem,
environment, process namespace, and credential material, and it accepts only
constrained, policy-checked requests from the sandbox — never raw untrusted
code, templates, deserialization payloads, or arbitrary command arguments. A
broker that sits beside the sandbox but shares its filesystem/env, or that
forwards unconstrained requests, is not a protected domain.

**Litmus test:** Does this credential or privileged action live in a domain
that executes untrusted input? If yes, it is on the wrong side of the boundary.

## Secrets

### Never commit

- API keys, tokens, passwords
- Private keys, certificates
- Database connection strings with credentials
- OAuth tokens, refresh tokens, session IDs

### .gitignore patterns

```gitignore
# Secrets — never commit
*.env
*.env.*
config.local.json
**/secrets/**
*.pem
*.key
```

### Reference from environment, never hardcode

```bash
# Good
DATABASE_URL=${DATABASE_URL}

# Bad — real credentials inlined (placeholders shown; never commit actual ones)
DATABASE_URL=postgres://<credentials>@<host>/<db>
```

```typescript
// Bad — hardcoded (placeholder shown; never commit a real key)
const API_KEY = "<key>";

// Bad — logging secrets
console.error(`Using API key: ${apiKey}`);

// Good — from config
const { apiKey } = getConfig();
```

### Required files

- `.env.example` — template with placeholder values (committed)
- `.env` — actual values (gitignored)

### Pre-commit check

```bash
git diff --staged | grep -iE "(api_key|password|secret|token|credential)" && echo "WARNING: possible secrets detected"
```

## Input Validation

### Validate at system boundaries

- API request handlers
- CLI argument parsing
- File uploads
- User-provided URLs
- MCP tool arguments

### Path sanitization

```typescript
import path from "path";

/**
 * `allowBase` is a CALLER decision, never data: it must be a literal at the
 * call site (or derive from the caller's own config), never from user input —
 * an attacker who controls the options object controls the boundary itself.
 */
function validatePath(
  userPath: string,
  allowedBase: string,
  { allowBase = false }: { allowBase?: boolean } = {},
): boolean {
  const base = path.resolve(allowedBase);
  const resolved = path.resolve(base, userPath);
  // Compare by path segment, not string prefix: `/project` must NOT accept
  // `/project-sibling/secret`.
  // An empty or "." userPath resolves to base itself. Secure by default (P15):
  // that is REJECTED unless the caller opts in with allowBase — "no path" must
  // be an explicit grant, not an accident.
  if (resolved === base) return allowBase;
  return resolved.startsWith(base + path.sep);
}

// Usage
if (!validatePath(requestedFile, projectRoot)) {
  return errorResponse("INVALID_PATH", "Path outside allowed directory");
}
```

### Sanitize home-directory paths in output

```typescript
import path from "path";

function sanitizePath(p: string): string {
  const home = process.env.HOME || process.env.USERPROFILE || "";
  // Segment-aware AND cross-platform: `/home/john` must NOT rewrite
  // `/home/johnson/...`; use path.sep so it works on Windows (`\`) too.
  if (home && (p === home || p.startsWith(home + path.sep))) return "~" + p.slice(home.length);
  return p;
}

// Bad — exposes username
console.error(`File not found: /Users/john/project/file.txt`);

// Good — sanitized
console.error(`File not found: ${sanitizePath(absolutePath)}`);
```

## Error Sanitization

Never expose stack traces, queries, or internal paths in error responses:

```typescript
// Bad
return { error: { message: error.stack } };

// Good — sanitizeError maps an internal error to a safe, generic message
return {
  error: {
    code: "INTERNAL_ERROR",
    message: sanitizeError(error),
  },
};
```

Define `sanitizeError` once per project. Reference implementation — log the
full error internally, return only a generic message to the caller:

```typescript
function sanitizeError(error: unknown): string {
  // Full detail goes to internal logs only (redacted per observability rules).
  logger.error("internal error", { error });
  // The caller sees a generic message — never the stack, query, or path.
  return "An internal error occurred";
}
```

## Cloud CLI Restrictions

**AI assistants must NOT execute cloud deployment commands.** Deployments are
human-initiated only. Blocked unless the human explicitly invokes:

| CLI | Service |
|-----|---------|
| `fly`, `flyctl` | Fly.io |
| `vercel` | Vercel |
| `netlify` | Netlify |
| `aws` | Amazon Web Services |
| `gcloud` | Google Cloud |
| `az` | Microsoft Azure |
| `firebase` | Firebase |
| `supabase` | Supabase |
| `wrangler` | Cloudflare Workers |
| `terraform apply`, `pulumi up` | IaC apply |

Read-only operations (`fly status`, `fly logs`) are allowed. Apply/deploy
operations require human invocation.

## Dependency Security

- Review new dependencies before adding
- Keep dependencies updated
- Always commit lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `uv.lock`)

## GitHub Actions

See `20support/standards/ci-security-policy.md` for the full policy. Summary:

- Pin all third-party actions to a full commit SHA, never a tag
- Never hardcode secrets in workflow files
- Use least-privilege `permissions:` in workflow files

## Security Checklist

Before committing:

- [ ] No API keys or secrets in code
- [ ] No hardcoded credentials
- [ ] Paths sanitized in error messages
- [ ] User input validated at boundaries
- [ ] Error messages don't expose internals
- [ ] Sensitive fields redacted in logs

## Reporting Security Issues

If you discover a security vulnerability:

1. Do NOT create a public issue
2. Contact maintainers directly
3. Allow reasonable time for fix before disclosure

Repo-specific additions: see `security-local.md` (loaded alongside this file).
That file is optional — if it does not exist, this repo has no repo-specific
security instantiation and this file stands alone. Create `security-local.md`
only when there is something repo-specific to record (e.g. the Trust Boundary
instantiation above: which process is the sandbox, which credentials are at
stake, where the protected domain lives).

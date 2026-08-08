<!-- cl-sync src=82e30631 -->
# Testing Pattern

Principles: P2 (No Silent Degradation), P3 (Transparent Evolution)

Tests exist to fail when the code regresses. A test that stays green after the
behavior it guards has changed is worse than no test — it manufactures
confidence. Two recurring traps below hollow out type-level tests in exactly
this way.

## Test Type Narrowing Exhaustively

When a type guard narrows to a union — or a union member is added or removed —
assert exhaustiveness at **compile time**, not by sampling representative
values. A value-sampling test only exercises the members you remembered to
write; the member you forgot is the one that regresses.

Two mechanisms fail the build the moment the union changes:

### never-default switch

```typescript
type Shape = Circle | Square | Triangle;

function assertNever(x: never): never {
  throw new Error(`unhandled union member: ${JSON.stringify(x)}`);
}

// Good — adding a 4th member to Shape makes this stop compiling
function area(s: Shape): number {
  switch (s.kind) {
    case "circle":   return Math.PI * s.r ** 2;
    case "square":   return s.side ** 2;
    case "triangle": return (s.base * s.height) / 2;
    default:         return assertNever(s); // s is `never` only if every member is handled
  }
}
```

### conditional-type probe

When there is no runtime switch to hang `assertNever` off — e.g. asserting the
return type of a guard, or that a parsed value stays within an intended union —
probe the type directly. Use a **bidirectional** equality check, not a one-way
`extends`. A one-way probe (`[Parsed] extends ["a" | "b" | "c"]`) only catches
_widening_: it stays green when a member is **removed**, because a narrower
`"a" | "b"` still satisfies `extends`. To fail on both extra and missing members
you must assert the two types are mutually assignable — and guard against `any`,
which is assignable to and from *every* type and so would sail through a bare
mutual-assignability check. A regression that collapses `Parsed` to `any` (a lost
generic, an untyped `JSON.parse`) is exactly the widening this probe must catch,
so reject `any` before comparing:

```typescript
type Expect<T extends true> = T;

// `any` is mutually assignable with every type, so it would pass a bare
// bidirectional check — detect it first. Only `any` satisfies `0 extends 1 & T`.
type IsAny<T> = 0 extends 1 & T ? true : false;

// Mutual assignability — true only when A and B are the same set of members,
// and false the moment either side degrades to `any`. The tuple wrapping
// ([A] / [B]) defeats union distributivity, so the check compares the unions
// as wholes rather than member-by-member.
type Exact<A, B> = IsAny<A> extends true
  ? false
  : IsAny<B> extends true
    ? false
    : [A] extends [B]
      ? [B] extends [A] ? true : false
      : false;

// Good — fails to compile if `Parsed` widens beyond, OR narrows below, the
// intended union (a forgotten or deleted member fails just as loudly as a
// stray one), and also if `Parsed` regresses to `any`.
type _ExhaustiveParsed = Expect<Exact<Parsed, "a" | "b" | "c">>;
```

## `@ts-expect-error` Is Not Verified Under esbuild-Transpiled vitest

`@ts-expect-error` is a compiler directive, not a runtime assertion. vitest
(and jest) transpile test files with esbuild/swc, which strips types **without
type-checking** — so a `@ts-expect-error` that no longer suppresses anything
(because the error it guarded is gone) passes silently. The "test" proves
nothing.

```typescript
// Bad — green under `vitest run`, verifies NOTHING (esbuild never type-checks)
// @ts-expect-error value is outside the union
const x: Direction = "sideways";
```

**Rule:** verify type-level expectations with something that fails the build —
the `assertNever` / conditional-type probes above, checked by `tsc` in the same
gate that runs the tests. Reserve `@ts-expect-error` for suites where a separate
`tsc --noEmit` over the test files is part of `make check`; if type-checking the
test files is not wired into the gate, treat `@ts-expect-error` as
documentation, not verification.

Both traps recur across the fleet — the exhaustiveness rule landed on 5 of 6
PRs in one adr-code-align batch (mbot#1533 review; rule as codified in
mbot#1539).

Repo-specific additions: see `testing-local.md` (loaded alongside this file).

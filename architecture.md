---
title: Architecture
layout: default
nav_order: 4
description: "How Provasign is built: a single binary with the Grove code-knowledge-graph engine embedded in-process. No daemon, no ports, no tokens."
permalink: /architecture/
---

# Architecture
{: .no_toc }

Provasign is a **single Go binary**. There is no server to run, no port to open, no token to manage, and no background daemon. Everything — intent capture, policy gates, test selection, impact analysis, Ed25519 signing, and audit replay — happens in-process when your agent (or you) invokes it.

The engine that makes Provasign *understand your code* rather than just scan diffs is **Grove**, and it is compiled directly into the Provasign binary.

1. TOC
{:toc}

---

## Grove — the knowledge-graph engine inside Provasign

**Grove is the code knowledge graph that Provasign runs on.** It is not a separate service you install or connect to — Provasign links against the Go library `grove/pkg/grove` and calls it directly in the same process.

Where a diff scanner sees *lines changed*, Grove sees *symbols changed and everything connected to them*. That is what lets Provasign answer the questions a certification gate actually needs to answer:

- **What does this change break?** — blast radius across the whole repository, not just the edited file.
- **Which tests cover the changed symbols?** — so certification runs the *relevant* suite, not all of it or none of it.
- **What is the dependency chain from here?** — for breaking-change and policy reasoning.

### How Grove models your code

Grove parses your source with Tree-sitter into a persistent SQLite graph and keeps it current with delta indexing — a file whose git blob SHA hasn't changed is never re-parsed.

| Layer | What it does |
|---|---|
| **Parse** | Tree-sitter AST extractors for 11 languages (Go, TypeScript/TSX, JavaScript, Python, Java, Rust, C, C++, C#, PHP); all CGO is isolated here |
| **Store** | SQLite in **WAL mode** + **FTS5** full-text search; delta indexing keyed on git blob SHA |
| **Graph** | In-memory `CodeGraph` with **8 typed edges**, BFS traversal |
| **Query** | intent→symbols (FTS5 + BFS), blast radius, deps, test selection, ICR (Isolated Change Region) |
| **Semantic** | `potion-base-8M` Model2Vec embeddings (29 MB) compiled in via `go:embed` — pure-Go inference, **no GPU, no API key, no CGO** |

The eight edge types — `defines`, `contains`, `imports`, `extends`, `implements`, `calls`, `uses-type`, `tests` — are what turn a pile of files into a graph you can traverse. `calls` and `uses-type` are deliberately scoped to the same file plus imported files; unscoped, a function named `parse` would appear to call every `parse` in the repo and produce ~5× false-positive edges.

Symbols are addressed as `{filePath}::{qualifiedName}@{blobSHA}`, so a symbol identity is stable until its content actually changes.

### One graph per repository

Each repository has exactly one Grove database at `<repo>/.grove/grove.db`. Provasign opens it in-process; so can the standalone `grove` CLI, Prism, and Fuse if you use them. WAL mode handles concurrent readers, and Grove uses a single writer connection with a 30-second busy timeout so multiple agents (Claude Code + Copilot + a Provasign pre-push hook) don't collide.

> **Why embedded, not a daemon?** Per-project Grove daemons created port collisions, per-repo token mismatches, and an opaque multi-process failure mode. The library model gives zero-config startup, hermetic installs, and a single canonical knowledge graph per repo. There is no `grove serve`, no `$GROVE_URL`, no shared secret.

---

## The Provasign binary

Provasign sits on top of Grove and adds the certification machinery:

```
┌──────────────────────────────────────────────────────────┐
│  provasign  (single binary)                                    │
│                                                            │
│  ┌─────────────┐   ┌──────────────┐   ┌────────────────┐   │
│  │ Intent      │   │ Policy gates │   │ Signer         │   │
│  │ capture     │   │ path·secrets │   │ Ed25519        │   │
│  │ (YAML)      │   │ fileclass    │   │ local key      │   │
│  └─────────────┘   │ deps·size    │   └────────────────┘   │
│                    │ coverage     │                        │
│  ┌─────────────┐   └──────────────┘   ┌────────────────┐   │
│  │ Analyzers   │                       │ Engine store   │   │
│  │ semgrep …   │   ┌──────────────┐    │ certs +        │   │
│  │ (downloaded │   │  Grove        │   │ changesets     │   │
│  │  on demand) │◄──┤  pkg/grove    │   │ (.provasign/       │   │
│  └─────────────┘   │  EMBEDDED     │   │  engine.db)    │   │
│                    │  impact·tests │    └────────────────┘   │
│                    │  deps·query   │                        │
│                    └──────┬────────┘                        │
└───────────────────────────┼────────────────────────────────┘
                            ▼
                  <repo>/.grove/grove.db   (one graph per repo)
```

Provasign calls Grove for the analysis that needs code understanding:

| Grove method | Provasign uses it for |
|---|---|
| `Impact(file, line)` | blast radius of a change during certification |
| `Tests(symbol)` | selecting the tests that actually cover the change |
| `Deps(file)` | dependency reasoning for policy gates |
| `Query(intent, limit)` | relating the captured intent to touched symbols |
| `Status()` | index freshness checks |

### Grove in action — the ICR

The most concrete way to understand what Grove adds is to look at what Provasign actually puts inside a certificate: the **ICR (Isolated Change Region)**.

**Scenario:** an AI agent is asked *"Fix the timing attack vulnerability in the password validation function."* One function is modified in `internal/auth/login.go`.

Grove traverses the code graph from that change and returns:

```
Symbols directly changed:
  internal/auth/login.go::validatePassword@a1b2c3d4

Blast radius (symbols that call or use-type the changed symbol):
  internal/auth/login.go::Login@e5f6a7b8
  internal/auth/middleware.go::RequireAuth@c9d0e1f2
  internal/api/handlers.go::PostLogin@a3b4c5d6

Tests Grove identifies as covering these symbols:
  internal/auth/login_test.go::TestValidatePassword@f7a8b9c0
  internal/auth/login_test.go::TestLogin_WrongPassword@d1e2f3a4
  internal/auth/integration_test.go::TestAuthFlow@b5c6d7e8
```

Provasign embeds all of this in the certificate as the ICR:

```json
{
  "symbols": [
    "internal/auth/login.go::validatePassword@a1b2c3d4",
    "internal/auth/login.go::Login@e5f6a7b8",
    "internal/auth/middleware.go::RequireAuth@c9d0e1f2",
    "internal/api/handlers.go::PostLogin@a3b4c5d6"
  ],
  "files": [
    "internal/auth/login.go",
    "internal/auth/middleware.go",
    "internal/api/handlers.go"
  ],
  "edges": 12,
  "confidence": 0.94,
  "hash": "sha256:7a3f9b2e1c8d4f6a0b5e3d9c7f2a4b8e1d6c3f9a2b7e4d1c8f5a3b6e9d2c7f4a"
}
```

The `hash` is `SHA-256` of the canonical `{symbols, files}` set. It appears in the admitted commit's trailer:

```
Intent-ID:             INT-2026-06-01-fix-timing-attack-in-validatepassword
Certificate-ID:        pvsign-cert-9c3d7a
ICR-Hash:              sha256:7a3f9b2e...
Effective-Config-Hash: sha256:4d8e1a...
Signed-By:             local-ed25519:9f3a2b1c
Signature:             MEQCIHx3... (base64)
```

**Why this matters:** a diff hash (e.g. `git show HEAD | sha256`) commits to the line changes. The ICR hash commits to the *semantic graph* of what changed — including symbols that weren't in the diff but are one hop away. Two commits that produce the same diff can have very different ICR hashes if one touches a function called by forty other things. The ICR hash is what makes the certificate a provable answer to *"what did the AI actually change?"* rather than just a signature over a log.

**What an auditor can do with it:**

- **Verify the certificate wasn't altered.** Recompute `SHA-256(canonical_json({symbols, files}))` from the symbol list and confirm it matches the `ICR-Hash` trailer. Any edit to the certificate to hide a symbol would break the hash.
- **Check intent vs. scope.** The intent says *"fix timing attack in validatePassword."* The ICR shows `validatePassword` was touched. It also shows `Login`, `RequireAuth`, `PostLogin` were in the blast radius. If a billing module had appeared in the symbol list, that would be a flag.
- **Confirm test coverage was meaningful.** The ICR names the specific tests Grove identified as covering the changed symbols — not just "tests passed" but *which tests, and why they count*.
- **Run `provasign cert replay`** to get `byte_reproducible` / `tool_drift` / `config_drift` — re-executing the gates against the recorded changeset months later. See [Audit use case]({{ '/use-cases/audit/' | relative_url }}).

Without Grove, Provasign can certify that *a build passed*. With Grove, it certifies *what changed, what it connects to, which tests cover it, and what the blast radius is* — and signs all of that as a unit.

### External analyzers are downloaded, not bundled

The heavy security tooling — semgrep, gitleaks, govulncheck, eslint, ruff, sonarlint-ls, a JRE — is **not** baked into the binary. `provasign tools install` fetches pinned versions on first use (Python/Node tools via pipx/npm). This keeps the binary small and lets you pin and audit exactly which analyzer versions produced a certificate.

---

## Local-first by design

| Property | Detail |
|---|---|
| **No network listeners** | Grove is in-process; Provasign's core flow opens no ports and runs no daemon |
| **No telemetry** | Nothing phones home; your source never leaves the machine |
| **Local signing key** | Ed25519 keypair at `<repo>/.provasign/keys/signing.ed25519.key` (mode `0600`), or `~/.provasign/keys/` with `--user`; generated on first use |
| **State in git + local SQLite** | Committed intents live in `.provasign/intents/`; certificates and changesets live in `.provasign/engine.db` (gitignored) |
| **Secrets via env only** | Credentials are never written into `.provasign/provasign.yaml` |

---

## Deployment modes

One binary, three modes — same config, same certificate format:

| Mode | State storage | Use case |
|---|---|---|
| **Laptop** *(shipped)* | SQLite + local Ed25519 key | Solo developer, zero infrastructure |
| **Team** *(roadmap)* | Postgres + Redis + KMS-backed signer | Shared audit trail across developers |
| **Air-gapped** *(roadmap)* | On-prem Postgres + HSM | Regulated industries, no external network |

The signer is an interface: laptop mode uses a local Ed25519 key; team mode swaps in a KMS-backed signer behind the same interface, so certificates keep the same shape.

> **Verification scope.** In laptop mode, certificates and the signing key live on the developer's machine (`.provasign/engine.db` and `.provasign/keys/`, both gitignored), so `provasign cert verify` / `provasign cert replay` are local to that machine. **Independent, cross-machine verification — by an auditor, a CI job, or a reviewer on a fresh clone — is a server (team) mode capability**, where a shared certificate store and a KMS-backed public key make admissions verifiable anywhere. Server mode is on the roadmap.

---

## Read more

- [How It Works]({{ '/how-it-works/' | relative_url }}) — the certify → sign → replay flow end to end
- [Features]({{ '/features/' | relative_url }}) — gates, certificates, and agent wiring
- [Other developer tools]({{ '/other-tools/' | relative_url }}) — Prism and Fuse, which embed the same Grove engine
- [Grove source on GitHub](https://github.com/provasign/grove#readme)

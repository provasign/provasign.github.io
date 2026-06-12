---
title: Grove
layout: default
nav_order: 5
description: "A persistent code graph for your repository — impact, tests, and dependencies, queryable by humans, tools, and agents."
permalink: /grove/
---

# Grove — your codebase as a graph, not a pile of files

Grep answers "does this string appear somewhere?" A language server answers
"where is this symbol defined?" Grove answers the questions that actually matter
before changing code:

- *What does changing this function break — across the entire codebase?*
- *Which tests cover this method, directly or transitively?*
- *What is the full dependency chain from this file?*
- *What symbols are semantically related to this task description?*

**What Grove does:** it parses your repository (Tree-sitter, 11 languages,
native semantic analyzers) into a persistent SQLite graph — symbols, calls,
imports, tests, 8 edge types — and keeps it live with delta indexing. Files
whose content hash hasn't changed are never re-parsed.

```sh
grove index .
grove symbols AuthService
grove impact internal/auth/service.go::AuthService.Login
grove tests  internal/auth/service.go::AuthService.Login
```

`impact` walks the call graph to show blast radius. `tests` returns the tests
that pin a symbol's behavior — including transitive coverage. Both answer in
milliseconds from the on-disk graph.

---

## Performance

Measured on real repositories (macOS, Apple Silicon, 2026-06-12), parallel
parsing and native analyzers enabled:

| Repo | Files | Symbols | Edges | Cold index | One-file change | No-change reindex (CLI) |
|---|---:|---:|---:|---:|---:|---:|
| [prometheus](https://github.com/prometheus/prometheus) | 1,476 | 14k | 259k | 12.2 s | — | 0.7 s |
| [django](https://github.com/django/django) | 3,792 | 39.5k | 425k | 18.5 s | — | 1.5 s |
| [grafana](https://github.com/grafana/grafana) | 18,979 | 98.5k | 1.16M | 56.6 s | 18.7 s | 9.5 s |

A **one-file change** re-parses one file, runs native analyzers only for
that file's language (other languages' edges are carried forward), and
diff-syncs the edge table — only changed rows are written. The
**no-change** CLI number is dominated by per-process graph rehydration; a
long-lived embedded engine (Prism, Fuse) pays it once at open, after which
a no-change reindex is milliseconds and queries run in-memory — BFS depth-3
over 50k nodes ≈ 4.5 ms, ranked search ≈ 15 ms at 50k symbols.

---

## How it works

```text
Source files
     │
     ▼
Tree-sitter AST walkers (11 languages)
+ Native semantic analyzers (Go, Python, Java, Rust, C, C++, C#, PHP, JS, TS)
+ Regex fallback for syntax-error recovery
     │ []SymbolRecord
     ▼
SQLite (WAL + FTS5)
  Delta indexing by git blob SHA
  Stale-file pruning
     │
     ▼
In-memory CodeGraph
  8 edge types · BFS traversal
     │
     ├── CLI commands
     ├── MCP stdio (9 tools)
     └── Embedded Go API (pkg/grove)
```

**Key design decisions:**

**Delta indexing by content hash.** Grove hashes each file before parsing. If
the stored hash matches, the file is skipped entirely. Indexing after a
one-line change in a 5,000-file repo touches one file, not 5,000.

**AST-first with native enrichment.** Tree-sitter produces a complete AST even
for files with syntax errors. When a subtree has errors, Grove runs both the
AST extractor and a regex fallback, then merges with AST taking precedence.
Language-native analyzers add higher-confidence call, type-use, inheritance,
and import edges when the local toolchain is available. Files being edited
mid-keystroke are still indexed usefully.

**Scoped edges prevent false positives.** `calls` and `uses-type` edges are
only created between symbols in the same file or in files connected by an
`imports` edge. Without this, a function named `parse` in one package would
appear to call a `parse` in an unrelated package — roughly 5× the false
positives.

---

## Graph edge types

| Edge | Meaning |
|---|---|
| `defines` | File defines this symbol |
| `contains` | Class/namespace contains this member |
| `imports` | File imports another file |
| `extends` | Class extends/embeds another |
| `implements` | Class implements an interface |
| `calls` | Function calls another function (scoped) |
| `uses-type` | Function/field uses a type (scoped) |
| `tests` | Test function covers a named symbol |

---

## Language support

11 languages, all with Tree-sitter AST + native semantic enrichment:

| Language | Extension(s) |
|---|---|
| Go | `.go` |
| TypeScript | `.ts` |
| TSX | `.tsx` |
| JavaScript / JSX | `.js`, `.jsx`, `.mjs`, `.cjs` |
| Python | `.py` |
| Java | `.java` |
| Rust | `.rs` |
| C | `.c`, `.h` |
| C++ | `.cc`, `.cpp`, `.cxx`, `.hh`, `.hpp` |
| C# | `.cs` |
| PHP | `.php`, `.phtml` |

Non-code files (`.md`, `.yaml`, `.json`, `.sh`, `.toml`, `.proto`, `.sql`,
`Makefile`, `Dockerfile`, and more) are indexed as `document` symbols in the
FTS5 full-text index, queryable semantically alongside code.

---

## Three ways in

| Surface | For |
|---|---|
| **CLI** | Humans, scripts, CI |
| **MCP stdio** (`grove mcp .`) | Any MCP-capable AI agent — 9 tools |
| **Embedded Go API** (`pkg/grove`) | Your own tools, in-process — how [Prism]({{ '/prism/' | relative_url }}) and Fuse use it |

Everything lives in `.grove/grove.db` — one SQLite file. Back it up, copy it,
or delete it to force a full reindex. No server, no port, no token.

---

## MCP tools

Nine tools over JSON-RPC 2.0 stdio, accessible to any MCP-capable agent.
Responses are token-disciplined: slim symbol shapes (no source bodies on the
wire), capped lists with true counts, compact JSON.

| Tool | Purpose |
|---|---|
| `grove_index` | Index or reindex a directory |
| `grove_symbols` | Search for symbols by name |
| `grove_query` | Retrieve ranked context for an intent |
| `grove_impact` | Blast radius — what breaks if this symbol changes? |
| `grove_deps` | Dependency tree for a file |
| `grove_tests` | Tests that cover a symbol (direct + transitive) |
| `grove_icr` | Isolated Change Region for an intent |
| `grove_conflicts` | Overlap check between two change regions |
| `grove_certify` | Conservative certification report for a unified diff |

Start the MCP server:

```sh
grove mcp .
```

For most AI agent use cases, `prism init` is the normal path — it starts Grove
automatically. Use `grove mcp` directly for custom integrations that need the
graph without Prism's context-ranking layer.

---

## Certification mode

`grove certify` maps unified diff hunks to indexed symbols and emits a JSON
report: changed files, changed symbols, impacted symbols, related tests,
unknowns, findings, and a verdict.

| Verdict | Meaning |
|---|---|
| `allow` | Grove mapped the diff to indexed symbols and found required test evidence |
| `manual_review` | Evidence is incomplete — unsupported files, unmapped hunks, missing tests, ignored/sensitive paths |
| `block` | Diff is malformed or cannot be processed deterministically |

Verdicts are intentionally conservative. Certification is not a compiler or
language-server resolver — it stays structural and falls back to
`manual_review` whenever evidence is incomplete rather than overclaiming.

```sh
grove certify <diff-file-or-> [dir]
# Exit codes: 0 allow · 2 manual_review · 3 block · 1 runtime error
```

---

## Installation

{% include install.html repo="provasign/grove" curl="curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash" ps="irm https://raw.githubusercontent.com/provasign/grove/main/install.ps1 | iex" %}

```sh
# Pin a specific version
VERSION=v0.6.3 curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash
```

Installs to `~/bin` by default. Set `INSTALL_DIR=/usr/local/bin` to override.

Build from source: `make build && make install`.

---

## Graph diff — the drift primitive

`pkg/grove` exposes a structural diff between two snapshots of the graph:
added, removed, and changed symbols, detected renames, and
`BreakingChanges` (exported symbols removed or with a changed signature).
Symbols are matched by stable identity — file path + qualified name + kind —
so line shifts don't register; only real changes appear.

This is the primitive behind the toolchain's stale-context loop:
[Fuse]({{ '/fuse/' | relative_url }}) diffs the graph across every merge and
records the drift in `.git/fuse/drift.json`;
[Prism]({{ '/prism/' | relative_url }}) delivers it to agents mid-session so
nobody edits from a memory of code that no longer exists.

---

## Troubleshooting

**Indexing is slow on a very large repo.** The TypeScript program check
dominates polyglot repos on a cold index. Native analyzers default to a 5 s
timeout each — set `GROVE_NATIVE_TIMEOUT=60s` to let `go list`/`tsc` finish
on huge repos. Timeouts degrade gracefully (the affected language loses
native enrichment, AST edges remain) and are reported in the index
diagnostics.

**Results look stale or wrong.** Delete `.grove/grove.db` and reindex — the
whole index is that one SQLite file. Schema migrations run automatically on
open, so version upgrades never need a manual wipe.

**CLI queries feel slower than expected.** Each CLI invocation rehydrates
the graph from SQLite (see the no-change column in the performance table).
Long-lived consumers — Prism MCP, Fuse, your own `pkg/grove` embed — pay
that once at open, then query in memory.

**A directory you care about isn't indexed.** Indexing honors `.gitignore`
and `.groveignore` and skips dependency/build/cache directories and
secret-bearing filenames by design. Check those before suspecting a bug.

---

## CLI reference

```sh
grove init [dir]                    # create .grove/ config
grove index [dir]                   # index (skips unchanged files)
grove status [dir] [--refresh]

grove symbols <query> [dir]         # symbol search
grove query <intent> [dir]          # semantic query (embeddings + BFS)
grove impact <symbol> [dir]         # blast radius
grove tests <symbol> [dir]          # tests covering a symbol
grove certify <diff> [dir]          # structural certification

grove mcp [dir]                     # start MCP stdio server
```

Indexing respects `.gitignore` and `.groveignore`, skips dependency and build
directories, and avoids secret-bearing filenames and credential extensions.

---

## Where it fits

Grove is the **graph engine**. [Prism]({{ '/prism/' | relative_url }}) builds
the context-ranking layer on top of it, and
[Fuse]({{ '/fuse/' | relative_url }}) uses it to merge at the symbol level
and record drift evidence.
[Shale]({{ '/shale/' | relative_url }}) plans to use it for intent-to-diff
conformance. You can use Grove directly when you want graph queries — impact,
tests, deps, symbols — without the higher-level tools.

[Get Grove on GitHub →](https://github.com/provasign/grove){: .btn .btn-primary }

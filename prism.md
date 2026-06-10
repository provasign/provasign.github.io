---
title: Prism
layout: default
nav_order: 3
description: "Graph-ranked context delivery for AI coding agents — callers, tests, and blast radius without a dozen file reads."
permalink: /prism/
---

# Prism — graph-ranked context for AI coding agents

**The problem:** watch an agent work and you'll see the same ritual on every
task: grep for a symbol, open the file, open the caller, open the test, open
another file that turned out to be irrelevant… Each read costs tokens and time,
and the agent still misses the test that defines the behavior it's about to
change.

**What Prism does:** it answers the *follow-up* questions in one call. Give it
a task and a few anchor terms; it returns the code, callers, callees, tests,
docs, and coverage gaps — ranked by relevance to the task and packed into a
token budget.

```sh
prism query "fix auth rate limit tests" \
  --terms RateLimiter --include graph,tests,coverage_gaps --format text
```

One command returns: the `RateLimiter` source, the three places that call it,
the two tests that pin its contract, and a note that `RefillRate` has no direct
test coverage. That's the context an agent needs to change the code *safely* —
not just the lines that matched a grep.

---

## The division of labor

Prism is **not** a better `grep`. The two tools have different jobs:

| Tool | Job |
|---|---|
| `rg` / `grep` | Find the first anchor. Fast, cheap, perfect for that. |
| Prism | Everything after the anchor: *what calls this? what does it call? which tests define the contract? what's in the blast radius? what nearby code has no tests?* |

The recommended workflow is: locate the anchor with `rg`, then run one Prism
command to get the complete relational context.

```text
rg buildCoverageGaps internal/
  → prism query "write tests for buildCoverageGaps" \
      --terms buildCoverageGaps \
      --include graph,tests,coverage_gaps \
      --format text
```

---

## Benchmark: real maintenance scenarios

Five real maintenance tasks on the Prism codebase itself, run both ways on
2026-06-07. Shell-only baseline: `rg` plus targeted file reads. Prism: one
CLI text command per scenario.

| Scenario | Shell bytes | Prism bytes | Reduction |
|---|---:|---:|---:|
| Init `agent_mode` / CLI steering impact | 19,970 | 12,818 | **35.8%** |
| `coverage_gaps` precision | 21,226 | 17,145 | **19.2%** |
| CLI text/lean/json output formatting | 15,820 | 14,198 | **10.3%** |
| Session cache / savings ledger | 33,134 | 19,922 | **39.9%** |
| Release/version/install wiring | 21,246 | 12,157 | **42.8%** |
| **Average** | | | **29.6%** |

The bigger correctness win is that Prism surfaces tests and coverage gaps
**proactively**. Shell-only workflows often discover those after CI fails.

Two distinct saving mechanisms:

1. **Context-gathering reduction.** One graph-aware query replaces 5–6 shell
   searches and file reads. This is what CLI benchmarks measure.
2. **Session deduplication** (MCP persistent transport). Repeat reads of
   an unchanged file collapse to a ~10-token SHA pointer, which is where the
   ~99% repeated-read savings come from. This only applies in persistent MCP
   sessions — not in single-shot CLI invocations.

Full benchmark reports: [CLI real-world](https://github.com/provasign/prism/blob/main/docs/Prism-CLI-Real-World-Benchmark-2026-06-07.md) ·
[Payflow A/B controlled test](https://github.com/provasign/prism/blob/main/docs/AB-Test-Payflow-2026-06-07.md)

---

## How it works

Prism builds on [Grove]({{ '/grove/' | relative_url }}) — the persistent code
graph — embedded directly in the Prism binary. No daemon, no port, no separate
setup.

```text
Task + anchor terms
      │
      ▼
Grove index (symbols, calls, imports, tests, 8 edge types)
      │
      ▼
Prism ranking
  • graph distance from anchor
  • semantic similarity to task
  • test relevance
  • recency / edit frequency
      │
      ▼
Budgeted text context
  • target symbols (source code)
  • callers / callees
  • tests that pin the contract
  • docs
  • coverage gaps (exported symbols with no direct test)
```

`--format text` gives agents plain, source-like context with short headers —
no JSON metadata wrappers inflating the bill. `lean` and `json` are available
for automation that needs structured output.

---

## Installation

```sh
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/provasign/prism/main/install.ps1 | iex

# Pin a version
VERSION=v0.5.6 curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
```

Installs to `~/bin` by default. Set `INSTALL_DIR=/usr/local/bin` to override.

---

## Setup

```sh
prism init . --mode both
prism index .
```

`prism init` writes:

- `prism.yaml` with `agent_mode: "both"`
- `.mcp.json` wiring the MCP server for MCP-capable clients
- Steering blocks in `CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
  `.windsurfrules`, `.github/copilot-instructions.md`, and other agent
  instruction files present in the repo

**Three modes:**

| Mode | When to use |
|---|---|
| `both` (recommended) | MCP tools as primary surface for the main agent; CLI fallback for subagents that don't inherit the MCP session |
| `mcp` | MCP-only; for environments with first-class MCP support and persistent sessions |
| `cli` | CLI-only; for environments without MCP support |

After `prism init`, agents follow instructions like:

```sh
# Relational context for a task
prism query "trace the payment refund flow" \
  --terms RefundPayment --include graph,tests --format text

# Coverage gaps — proactive, before CI fails
prism query "find gaps" \
  --terms UpdatePayment --include coverage_gaps --format text

# Whole file
prism read internal/payment/service.go --format text

# One known symbol
prism lookup github.com/example/payflow/internal/payment.(*Service).RefundPayment --format text
```

Indexing 5,000 files takes seconds; the graph updates incrementally — only
modified files are re-parsed on subsequent runs.

---

## Language support

11 languages, all with Tree-sitter AST + native semantic enrichment:

| Language | Extensions |
|---|---|
| Go | `.go` |
| TypeScript / TSX | `.ts`, `.tsx` |
| JavaScript / JSX | `.js`, `.jsx`, `.mjs`, `.cjs` |
| Python | `.py` |
| Java | `.java` |
| Rust | `.rs` |
| C / C++ | `.c`, `.h`, `.cc`, `.cpp`, `.hpp` |
| C# | `.cs` |
| PHP | `.php`, `.phtml` |

Non-code files (Markdown, YAML, JSON, shell, Dockerfiles, SQL, etc.) are
indexed as document symbols in the FTS5 full-text index and can be requested
with `--include docs`.

---

## MCP tools

When running in MCP mode, nine tools are available to agents:

| Tool | Purpose |
|---|---|
| `prism_query` | Graph-ranked context for a task + anchor terms |
| `prism_read` | Full file content (deduplicates unchanged reads in session) |
| `prism_lookup` | Single known symbol — function, method, type |
| `prism_search` | Keyword search across the indexed codebase |
| `prism_index` | Trigger reindex (after large changes) |
| `prism_savings` | Show session token savings so far |
| `prism_feedback` | Rate a context result (improves ranking weights) |
| `prism_compact` | Compact the session savings ledger |
| `prism_evidence` | Retrieve indexing evidence for a path |

---

## CLI reference

```sh
prism init [--global] [--mode cli|mcp|both] [dir]
prism index [dir]
prism status [dir]

prism query <task> [dir] \
  --terms a,b,c \
  --include graph,tests,docs,coverage_gaps \
  --depth 2 \
  --format text|lean|json

prism read <file> [dir] --format text
prism lookup <symbol> [dir] --format text
prism search <keyword> [dir] --format text
prism savings [dir]
prism mcp [dir]
prism serve [--port 8888] [dir]
prism version
```

---

## Configuration

`prism.yaml` is intentionally small:

```yaml
version: 1
profile: "default"
agent_mode: "both"
```

Environment overrides: `PRISM_MODEL`, `PRISM_PROFILE`, `PRISM_GROVE_BINARY`,
`PRISM_EMBEDDINGS_BACKEND`.

---

## Where it fits

Prism is the **context layer**. [Shale]({{ '/shale/' | relative_url }}) is the
**evidence layer** — what the agent did, on the PR.
[Grove]({{ '/grove/' | relative_url }}) is the **graph engine** both build on,
available directly when you want graph queries without Prism's context-ranking
layer. Use any of them alone; no shared account or server required.

[Get Prism on GitHub →](https://github.com/provasign/prism){: .btn .btn-primary }

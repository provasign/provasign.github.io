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

The claims on this page are measured, not asserted — controlled study,
independent oracles, open data. Correctness and completeness are always the
headline; efficiency is reported next to them, never alone. For
transparency we also benchmark Prism against other open-source context
tools on the same oracles, publishing every raw run: see
**[Benchmarks](/benchmarks/)**.

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

**Delivered edit-ready.** For a bug fix or an implement task, that one command
returns the relevant code as **verbatim, line-numbered source windows** — the
same shape the agent's own read tool produces — plus each anchor's callers and
covering tests. The agent edits straight away instead of re-reading, and an
unchanged file it already received this session comes back as a ~10-token
pointer. Delivery is chosen from the task (bug-fix/implement → source;
exploration/review → the compact symbol list), or set explicitly with
`--delivery`.

---

## Benchmarks

One task, three ways to search — same agent, same frontier model, only the
tool changes. A signature change in **jackson-databind**: find all **8 call
sites** it breaks, including callers not named after the method (invisible to
text search). Oracle-scored.

| Tool | Correct | Turns | Tokens | Cost |
|---|---:|---:|---:|---:|
| Plain grep — the agent's default | 62% | 19 | 376K | $0.90 |
| **Prism** | **100%** | **3** | **60K** | **$0.14** |

Fewer turns, fewer tokens, lower cost — and the only one that got the whole
answer. Run the same task through **Mason** (Prism built in) on a **free local
30B model**: **100% correct at $0** (0.997 mean recall across the 7-task
change-impact benchmark). Raw runs: [provasign/research](https://github.com/provasign/research).

Prism saves tokens two different ways, and they compound. The first is
measured per-query; the second compounds across a whole session.

### 1. Context gathering — one query replaces 5–6 reads

Five real maintenance tasks on the Prism codebase itself, run both ways
(2026-06-07). Shell-only baseline: `rg` plus targeted file reads. Prism: one
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

### 2. Repeat reads — the savings that compound all session long

This is the dimension a single-query benchmark can't capture, and it's the
larger number over a real session. In a persistent MCP session, Prism
remembers every file it has already delivered. The **first** read returns the
content (already trimmed by progressive disclosure); **every read after that**
of an unchanged file collapses to a ~10-token SHA pointer instead of the full
file.

Measured across four project sizes (2026-05-27), token savings on the *same
file* by read number:

| Project | Files | 1st read | 2nd read | 3rd read |
|---|---:|---:|---:|---:|
| Small | 61 | 0% | **67.5%** | **67.5%** |
| Medium | 801 | 56.1% | **67.1%** | **67.1%** |
| Large | 4,501 | 56.1% | **67.1%** | **67.1%** |
| Monorepo | 9,901 | 0% | **58.0%** | **58.0%** |

Those are session-level aggregates. The underlying mechanism is sharper still:
a single large file re-read drops from its full token cost to ~10 tokens — a
**~99% reduction on that read**. Agents re-open the same handful of files
constantly — the file they're editing, the test that pins it, the interface it
implements — so across a 20-query session these repeat-read savings dwarf the
per-query context-gathering win.

Watch it accumulate live:

```sh
prism savings .      # delivered vs. original tokens, per tool, this session
```

> **Repeat-read dedup only applies in persistent MCP sessions** (`--mode both`
> or `mcp`). Single-shot CLI invocations are process-per-command, so each one
> starts cold — they benefit from context-gathering reduction (mechanism 1),
> not session dedup.

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

{% include install.html repo="provasign/prism" formula="provasign/shale/prism" curl="curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash" ps="irm https://raw.githubusercontent.com/provasign/prism/main/install.ps1 | iex" %}

```sh
# Pin a version
VERSION=v0.17.0 curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
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

Indexing 5,000 files takes seconds; a 19k-file monorepo (Grafana) cold-indexes
in ~54 s and rescans in ~8 s when nothing changed. The graph updates
incrementally — only modified files are re-parsed. Measured scale numbers are
on the [Benchmarks](/benchmarks/) page.

---

## Change impact

When you need every site affected by a method signature change — declaration,
overrides, and all callers — one call covers the full blast radius:

```sh
prism change-impact 'BaseDatabaseOperations.quote_name'
```

or, in MCP sessions:

```
prism_change_impact(query="BaseDatabaseOperations.quote_name")
```

The engine traverses the type graph, not text: it finds callers that reach the
method through an interface, a base class, or an indirect receiver chain — sites
that grep would miss. Results come back in four groups:

| Group | Contents |
|---|---|
| `declarations` | The method itself, across all files |
| `family` | Every override and implementation in the subtype closure |
| `supers` | Supertype declarations (informational — contracts this project doesn't own) |
| `callers` | All resolved call sites into the set |

Check the `completeness` field: `closed` means the set is authoritative.
`project-local + overridesExternal` means the method belongs to an external
contract (JDK, third-party library) — its signature cannot safely change, and
calls typed against the external supertype are not included. Querying an external
type directly (e.g. `Iterator.next`) returns the project's full implementation
closure, which is useful for migration sweeps.

Relay the result as-is. Re-running grep after to "verify" measurably drops real
sites and adds spurious ones — the engine already solved the traversal.

Change impact is one of six **task-shaped operations** — traversals agents
otherwise orchestrate over many turns, computed in the engine as one
deterministic call each:

| Operation | Question it answers |
|---|---|
| `prism change-impact 'Type.method'` | What must change if this signature changes? |
| `prism missing-implementations 'Type.method'` | Which types claiming this contract don't implement it — who breaks once the member is required? Under a default body, who inherits the default and breaks if it becomes abstract? |
| `prism untested-surface 'Type.method'` | Which parts of the change-set have no test within 3 resolved caller hops — what should be tested first? |
| `prism dead-code [--roots a,b]` | Which production functions/methods does nothing reach? Precision-first: unreachable, non-exported, and name-unreferenced — safe to delete without breaking compilation. Caveats (reflection, DI, codegen) are part of the answer. |
| `prism rename-plan 'Type.method' NewName` | The rename as concrete line edits — file, line, before, after — for every declaration, override, and resolved call site. Review and apply; ambiguous lines are bucketed separately, never silently included. |
| `prism affected <files…>` | Which tests cover these changed files? `git diff --name-only \| xargs prism affected` → run only those tests. Pre-commit and CI test selection via the graph's test edges. |

And a background watcher keeps everything warm:

```sh
prism watch .    # delta-reindex on every save — queries never wait for indexing
```

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

When running in MCP mode, fifteen tools are advertised to agents via
`tools/list` — deliberately a narrow surface, so steering stays unambiguous:

| Tool | Purpose |
|---|---|
| `prism_change_impact` | Deterministic change-set for a method signature change — declaration, override/implementation family, and all resolved callers in one engine call |
| `prism_missing_implementations` | Types claiming a contract that do not implement the member — missing / abstract / unverifiable buckets |
| `prism_untested_surface` | The change-set partitioned by covering-test evidence — write tests for the untested list first |
| `prism_dead_code` | Unreachable production functions/methods — precision-first deletion candidates with caveats |
| `prism_rename_plan` | The change-impact set converted to concrete line edits with suggested substitutions — review-and-apply |
| `prism_affected` | Every test covering a set of changed files — pre-commit / CI test selection |
| `prism_query` | Graph-ranked context for a task + anchor terms |
| `prism_read` | Full file content (deduplicates unchanged reads in session) |
| `prism_lookup` | Single known symbol — function, method, type |
| `prism_edges` | Walk one hop from a symbol: callers, callees, tests, implementations |
| `prism_references` | Every code use of a symbol, grouped by file |
| `prism_resolve` | Disambiguate a name to exact file:line definitions |
| `prism_search` | Keyword search across indexed symbol names |
| `prism_index` | Trigger reindex (after large changes) |
| `prism_drift` | Report files/symbols that changed since they were delivered this session |

Four session utilities exist alongside them (invocable by name or via the
CLI, not advertised in `tools/list` — they are operator tools, not steering
targets):

| Utility | Purpose |
|---|---|
| `prism_savings` | Show session token savings so far |
| `prism_feedback` | Rate a context result (improves ranking weights) |
| `prism_compact` | Compact the session savings ledger |
| `prism_evidence` | Convert sub-agent prose summaries into typed, dereferenceable citations |

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
prism references <name> [dir] --format text
prism change-impact <Type.method[(ParamType,...)> [dir] --format text|lean|json
prism rename-plan <Type.method> <NewName> [dir] --format text|lean|json
prism missing-implementations <Type.method> [dir] --format text|lean|json
prism untested-surface <Type.method> [dir] --format text|lean|json
prism dead-code [dir] [--roots a,b] --format text|lean|json
prism affected <file> [file ...] [dir] --format text|json
prism watch [dir]
prism drift [dir]
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
layer. [Mason]({{ '/mason/' | relative_url }}) is the **agent layer** — a
model-agnostic coding agent with Prism baked into the harness, no MCP setup or
steering files needed. Use any of them alone; no shared account or server
required.

[Get Prism on GitHub →](https://github.com/provasign/prism){: .btn .btn-primary }

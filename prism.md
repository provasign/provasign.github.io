---
title: Prism
layout: default
nav_order: 2
description: "Semantic change intelligence for developers, coding agents, and CI — complete impact, tests, and concrete edit plans in deterministic operations."
permalink: /prism/
---

# Prism — semantic change intelligence for every developer and coding agent

**The problem:** a code change is relational, but most developer tools begin
with text. Humans and agents both repeat the same ritual: find a symbol, inspect
its declaration, chase implementations and callers, locate the tests, and hope
nothing important stayed invisible.

**What Prism does:** it turns those follow-up questions into deterministic,
task-shaped operations. Give it a method and get the complete change set. Give
it a diff and get every site the change missed. Give it a task and anchors and
get ranked, edit-ready code context within a token budget.

```sh
prism query "fix auth rate limit tests" \
  --terms RateLimiter --include graph --format text
```

One command returns: the `RateLimiter` source as line-numbered windows, the
three places that call it, and the tests that pin its contract — edit-ready.
That's the context an agent needs to change the code *safely* — not just the
lines that matched a grep.

The claims on this page are measured, not asserted — controlled study,
independent oracles, open data. Correctness and completeness are always the
headline; efficiency is reported next to them, never alone. For
transparency we also benchmark Prism against other open-source context
tools on the same oracles, publishing every raw run: see
**[Benchmarks](/benchmarks/)**.

---

## The division of labor

Locating and relating are different jobs — Prism covers both, priced
separately:

| Need | Route |
|---|---|
| Find the first anchor | `prism search <term> --scope text` — a real ripgrep pass inside Prism, exactly grep's results at grep's cost |
| Everything after the anchor | *what calls this? what does it call? which tests define the contract? what's in the blast radius?* — `prism query` and the task-shaped graph ops |

The recommended workflow is: locate the anchor (search), then run one Prism
command to get the complete relational context.

```text
prism search ToolSchemas --scope text
  → prism query "write tests for ToolSchemas" \
      --terms ToolSchemas \
      --include graph \
      --format text
```

**Delivered edit-ready.** For a bug fix or an implement task, that one command
returns the relevant code as **verbatim, line-numbered source windows** — the
same shape the agent's own read tool produces — plus each anchor's callers and
covering tests. The agent edits straight away instead of re-reading, and an
unchanged file it already received this session comes back as a ~30-token
pointer. Delivery is chosen from the task (bug-fix/implement → source;
exploration/review → the compact symbol list), or set explicitly with
`--delivery`.

---

## Benchmarks

One task, three ways to search — same agent, same frontier model, only the
tool changes. A signature change in **jackson-databind**: find all **8 call
sites** it breaks, including callers not named after the method (invisible to
text search). Oracle-scored.

| Tool | Sites found | Turns | Tokens | Cost |
|---|---:|---:|---:|---:|
| Plain grep — the agent's default | 8 of 8 | 32 | 1,117K | $1.60 |
| **Prism** | **8 of 8** | **3** | **59K** | **$0.16** |

*(Re-measured 2026-08-08 on Opus + prism v0.37.0. A 2026-08 frontier model
does grep its way to a complete change-set on this task — an earlier run of
this table, on the models of 2026-07, had it finding 5 of 8. What Prism
changes now is the cost: **10× fewer turns, 19× fewer tokens, 10× cheaper**.
On cheaper models the gap is still capability — see the tier table below.)* Run the same task through **Mason** (Prism built in) on a **free local
30B model**: **all 8, at $0** (0.997 mean recall across the 7-task
change-impact benchmark). Raw runs: [provasign/research](https://github.com/provasign/research).

Prism saves tokens two different ways, and they compound. The first is
measured per-query; the second compounds across a whole session.

### 1. Context gathering — one query replaces 5–6 reads

Five real maintenance tasks on the Prism codebase itself, run both ways
(2026-06-07). Shell-only baseline: `rg` plus targeted file reads. Prism: one
CLI text command per scenario.

| Scenario | Shell bytes | Prism bytes | Reduction |
|---|---:|---:|---:|
| Init steering block impact | 19,970 | 12,818 | **35.8%** |
| `coverage_gaps` precision | 21,226 | 17,145 | **19.2%** |
| CLI text/lean/json output formatting | 15,820 | 14,198 | **10.3%** |
| Session cache / savings ledger | 33,134 | 19,922 | **39.9%** |
| Release/version/install wiring | 21,246 | 12,157 | **42.8%** |
| **Average** | | | **29.6%** |

*(Historical run. The `coverage_gaps` scenario refers to a since-removed
feature: heuristic test-coverage edges measured 4–12% recall against real
runtime coverage and were removed rather than shipped.)*

### 2. Repeat reads — the savings that compound all session long

This is the dimension a single-query benchmark can't capture, and it's the
larger number over a real session. In a persistent MCP session, Prism
remembers every file it has already delivered. The **first** read returns the
content (already trimmed by progressive disclosure); **every read after that**
of an unchanged file collapses to a ~30-token SHA pointer instead of the full
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
a single large file re-read drops from its full token cost to ~30 tokens — a
**~95–99% reduction on that read**, depending on file size. Agents re-open the same handful of files
constantly — the file they're editing, the test that pins it, the interface it
implements — so across a 20-query session these repeat-read savings dwarf the
per-query context-gathering win.

Watch it accumulate live:

```sh
prism savings .      # delivered vs. original tokens, per tool — per-repo
                     # totals persist across processes (retained ~30 days)
```

> **Repeat-read dedup only applies in persistent MCP sessions** (the MCP path
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
Grove index (symbols, calls, imports, tests, 9 edge types incl. overrides)
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
prism init .
prism index .
```

`prism init` writes:

- `prism.yaml` with the ranking profile
- `.mcp.json` wiring the MCP server for MCP-capable clients
- Steering blocks in `CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
  `.windsurfrules`, `.github/copilot-instructions.md`, and other agent
  instruction files present in the repo

There are no modes to choose: one `prism init` registers the MCP servers and
writes a single steering block covering MCP tools (primary surface) and the
CLI (fallback for subagents that don't inherit the MCP session). `--mode` is
accepted and ignored since v0.38.0. Indexing is automatic — `prism index .`
is an optional warm-up.

**Routing is structural.** Steering alone does not route agents — measured
12:1, an agent will cite its instructions and run `grep` anyway. Interactive
`prism init` therefore offers (and `--deny-builtin-search` forces) denying
Claude Code's built-in Grep/`grep`/`rg` in `~/.claude/settings.json`, making
Prism the search path. Nothing becomes unfindable —
`prism search --scope text` is a ripgrep passthrough — and the change is
reversible by deleting those lines.

After `prism init`, agents follow instructions like:

```sh
# Relational context for a task
prism query "trace the payment refund flow" \
  --terms RefundPayment --include graph --format text

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
that grep would miss. Results come back in five groups:

| Group | Contents |
|---|---|
| `declarations` | The method itself, across all files |
| `family` | Every override and implementation in the subtype closure |
| `supers` | Same-member declarations on other contracts — sibling interfaces satisfied by the same implementations break under the change too |
| `callers` | All resolved call sites into the set |
| `declaringTypes` | Interface/type declaration blocks that textually change because their member specs are not separate symbols (Go/TS) — always change sites |

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
| `prism verify [--base REF]` | Is this diff complete? Detects contract changes, computes the required set from the *base* contract, and reports every dependent site the diff did not touch — line-precise, exit 1 if incomplete. |
| `prism node <symbol-or-file>` | Orientation for one node: a symbol's source plus a names-only menu of its graph neighbours, or a file's contents plus what defines and depends on it. |
| `prism dead-code [--roots a,b]` | Which production functions/methods does nothing reach? Precision-first: unreachable, non-exported, and name-unreferenced — safe to delete without breaking compilation. Caveats (reflection, DI, codegen) are part of the answer. |
| `prism rename-plan 'Type.method' NewName` | The rename as concrete line edits — file, line, before, after — for every declaration, override, and resolved call site. Review and apply; ambiguous lines are bucketed separately, never silently included. |

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

Over MCP, fourteen tools are advertised to agents via
`tools/list` — deliberately a narrow surface, because every extra tool is a
routing error waiting to happen. (An earlier unified `prism(task)` tool was
removed in v0.41.0: natural language must never be the sole retrieval key —
agents do better picking a route and passing confirmed anchors.)

| Tool | Purpose |
|---|---|
| `prism_change_impact` | Deterministic change-set for a method signature change — declaration, override/implementation family, and all resolved callers in one engine call |
| `prism_missing_implementations` | Types claiming a contract that do not implement the member — missing / abstract / unverifiable buckets |
| `prism_rename_plan` | The change-impact set converted to concrete line edits with suggested substitutions — review-and-apply |
| `prism_dead_code` | Unreachable production functions/methods — precision-first deletion candidates with caveats |
| `prism_map` | Components and every component-level dependency, with weights, cycles, and the evidence tier of each claim |
| `prism_query` | Graph-ranked context for a task + anchor terms, plus a real full-text pass over the same terms |
| `prism_search` | Symbol names **and** raw source text in one call (`scope="text"` for a pure ripgrep, `regex=true` for patterns) |
| `prism_read` | Full file content (unchanged re-reads collapse to a SHA pointer) |
| `prism_lookup` | Single known symbol — function, method, type |
| `prism_node` | One symbol's source plus its neighbour menu, or one file's contents plus its definitions and dependents |
| `prism_references` | Every code use of a symbol, grouped by file |
| `prism_verify` | Diff-completeness gate: what the change set should have been, and what the diff missed |
| `prism_arch_check` | Declared architecture rules validated against real edges |
| `prism_index` | Trigger reindex (delta indexing is automatic) |

### Text search is built in

`prism_search` and `prism_query` run a real ripgrep pass internally (falling
back to `grep`, then to a built-in scanner — `prism doctor` reports which).
Matches that no indexed symbol encloses — comments, config keys, string
literals, docs — come back as `textHits`/`textMatches`. An agent needs no
separate grep tool, and prices each request itself: `scope="text"` is a pure
grep, `scope="both"` (the default) merges symbol and text results.

Where a search is noisy, Prism says so rather than staying silent. Measured
across 127 symbols in six repositories, a whole-word grep for a symbol name
returns ~30% lines that are not resolved references to it (18% in
jackson-databind, 50% in gin, 98% in one typeorm case: 372 hits, 1 real). The
graph does not find lines grep misses — it tells you which hits matter.

### Repeat graph deliveries collapse

A repeat call to a whole-repo graph operation always **recomputes** — the
traversal is milliseconds, and freshness is proven rather than assumed. When
the fresh result is byte-identical to one already delivered this session,
Prism returns a one-line `[prism:cached]` pointer with group counts instead
of the payload. A result that changed by even one site is always delivered in
full: complete-set tools deliver complete sets, never deltas.

### CLI-only surfaces

These remain available by name and through the CLI, but are not advertised to
agents — their jobs are covered by the tools above (cycles are a field of
`prism map`'s result; `prism_search` disambiguates names and tags test
doubles), and they are operator tools rather than steering targets:

| Utility | Purpose |
|---|---|
| `prism_resolve` | Disambiguate a name to exact file:line definitions |
| `prism_edges` | Walk one hop from a symbol: callers, callees, implementations |
| `prism_cycles` | Dependency cycles only |
| `prism_drift` | Files/symbols that changed since they were delivered this session |
| `prism_savings` | Token-savings dashboard (CLI totals persist per repository, retained ~30 days) |
| `prism_feedback` | Rate a context result |
| `prism_compact` | Compress a conversation-history JSON array read from stdin |

---

## CLI reference

```sh
prism init [--global] [dir]
prism index [dir]
prism status [dir]

prism query <task> [dir] \
  --terms a,b,c \
  --include graph,docs \
  --format text|lean|json

prism read <file> [dir] --format text
prism lookup <symbol> [dir] --format text
prism search <keyword> [dir] --format text [--scope text|symbols|both] [--regex]
prism references <name> [dir] --format text
prism change-impact <Type.method[(ParamType,...)> [dir] --format text|lean|json
prism rename-plan <Type.method> <NewName> [dir] --format text|lean|json
prism missing-implementations <Type.method> [dir] --format text|lean|json
prism node <symbol-or-file> [dir] --format text|lean|json
prism dead-code [dir] [--roots a,b] --format text|lean|json
prism map [dir] [--depth N] [--component X] [--expand 'A->B'] --format text|json
prism cycles [dir] [--depth N] --format text|json
prism arch [dir]
prism verify [dir] [--base REF] --format text|json
prism doctor [dir]
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
```

Optional: `model: "<model-id>"` sizes context budgets (there is NO
auto-detection; unset means a safe 200k default), and repeatable
`arch_deny: "<from> -> <to>"` rules make `prism arch` a CI gate.
Environment overrides: `PRISM_MODEL`, `PRISM_PROFILE`.

---

## Other surfaces

Same engine, three more doors beyond MCP and the CLI:

- **HTTP** — `prism serve` exposes every tool as `POST /<tool_name>` on
  `127.0.0.1` (plus `GET /health`, `GET /status`) for curl and custom
  automation. Reference:
  [docs/HTTP_API.md](https://github.com/provasign/prism/blob/main/docs/HTTP_API.md).
- **Go library** — `pkg/kit` embeds the engine in-process:
  `kit.Open(dir)` then `Invoke("<tool_name>", args)`; this is what mason
  builds on. Reference:
  [docs/GO_KIT.md](https://github.com/provasign/prism/blob/main/docs/GO_KIT.md).

---

## Where it fits

Prism and [Shale]({{ '/shale/' | relative_url }}) are the two core projects:
Prism provides change intelligence before an edit; Shale carries evidence into
review after it. [Mason]({{ '/mason/' | relative_url }}) is the incubating
reference agent that proves both layers together. [Grove]({{ '/grove/' | relative_url }})
is the embedded semantic graph engine beneath Prism, available separately for
tool builders but not required as another product to install.

[Get Prism on GitHub →](https://github.com/provasign/prism){: .btn .btn-primary }

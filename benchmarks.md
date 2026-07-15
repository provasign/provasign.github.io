---
title: Benchmarks
layout: default
nav_order: 7
description: "Measured recall, cost, and turns for agentic grep vs graph primitives vs task-shaped operations — same tasks, same independent oracles."
permalink: /benchmarks/
---

# Benchmarks — measured, not vibes

**The principle every number here serves: correctness and completeness come
first.** Token savings and speed only matter at equal completeness — a
cheaper, faster *incomplete* change-set is a faster broken build. So recall
against ground truth is always the headline, and efficiency is only ever
reported next to it, never alone.

Every number on this page comes from a controlled, paired study: same task,
same repository, same model — only the tool guidance changes. Answers are
scored against **independent oracles** (Go: SSA/VTA; Java: a Spoon
type-resolution oracle; TypeScript: a ts-morph compiler oracle; Python: a
Jedi oracle), never against Prism's own engine. The full harness, tasks, run logs, and scoring code are
open source: [provasign/research](https://github.com/provasign/research).

The study compares the three ways coding agents consume a repository today:

| Arm | What the agent gets | Who uses this shape |
|---|---|---|
| **T** — text | shell search (grep/rg) + file reads | Claude Code, Cursor, Amp — the default everywhere |
| **G** — graph primitives | find-references, symbol lookup, per-hop navigation | LSP-based tools, most code-intel MCP servers |
| **G\*** — task-shaped | one deterministic call: `prism change-impact` returns the complete change-set | Prism |

The task: *"this method's signature is changing — list every site that must
change."* Miss a site and the build breaks. Six size-graded tasks in
jackson-databind (8 to 108 ground-truth sites), replicated in Commons
Collections, Guava, Grafana (Go), TypeORM (TypeScript), and Django (Python).

---

## Recall, cost, and turns by model tier

Six Java tasks, n=5 trials per cell, scored against the Spoon oracle:

| Tier | Arm | Mean recall | $/task | Agent turns |
|---|---|---|---|---|
| Haiku | T | 0.758 | 0.48 | 31 |
| Haiku | G | 0.833 | 0.53 | 41 |
| Haiku | **G\*** | **0.997** | **0.11** | **2.8** |
| Sonnet | T | 0.951 | 2.13 | 45 |
| Sonnet | G | 0.978 | 2.20 | 44 |
| Sonnet | **G\*** | **0.997** | **0.53** | **11.7** |
| Opus | T | 0.952 | 2.14 | 22 |
| Opus | G | 1.000 | 3.06 | 21 |
| Opus | **G\*** | 0.997 | **0.48** | **4.0** |
| Local 30B (free) | **G\*** | **0.997** | **$0** | **1.0** |

Two things to read off this table:

**At primitive altitude, completeness must be bought with model capability.**
The recall ladder (0.833 → 0.978 → 1.000) tracks the price ladder
($0.53 → $2.20 → $3.06). The agent is hand-orchestrating a traversal —
find the declaration, find the overrides, find the callers, dedup — and how
well it does that depends on how smart (expensive) it is.

**At task altitude the ladder collapses.** Every tier scores 0.997 — the
per-task recall values are *identical* across Haiku, Sonnet, Opus, and a free
local qwen3-coder:30b, including the one shared miss (an engine residual, not
a model failure). Once the traversal lives in the engine, completeness is a
property of the tool. The rational choice becomes the cheapest tier:
**$0.11/task (Haiku + G\*) beats $2.14/task (Opus + text) on both recall and
cost — 28× cheaper than frontier + primitives at a −0.003 recall difference.**

---

## Does it matter? Missed sites are compile errors

For a signature change, every site the agent misses is a method still using
the old signature — a build break when the change is applied:

| System | Missed sites (104-site task) | Tasks left broken |
|---|---|---|
| Opus + text | **30** | 1/6 |
| Sonnet + text | **26** | 1/6 |
| Haiku + text | **59** | 5/6 |
| Any tier + G\* (incl. free local) | **0** | 1/6* |

\* The single G\* residual: 2 sites on the 108-site task, behind chained
receivers the engine cannot yet resolve — shared identically by all four
tiers, confirming it is a tool property, fixable in one place.

On the 104-site task the gap is not statistical: Opus at $2.63/run leaves 30
methods broken; every G\* tier — including the free one — leaves none.

---

## Scale: 310 sites in Guava

`ForwardingObject.delegate()` — a blast radius 3× anything in the jackson
corpus:

| Tier | Arm | Recall | Turns | Wall | $ |
|---|---|---|---|---|---|
| Haiku | T | 0.171 | 41 | 173s | 0.43 |
| Haiku | **G\*** | **0.997** | 4 | 102s | 0.18 |
| Sonnet | T | 0.997 | 55 | 811s | 3.85 |
| Opus | T | 0.997 | 3 | 516s | 5.46 |
| Opus | **G\*** | **0.997** | 8 | 119s | 0.66 |
| Local 30B | **G\*** | **0.997** | **1** | 224s | **0** |

Honest note: Sonnet-text and Opus-text *tie* on recall here, because
`delegate()` is a globally unique, greppable name — the change-set is huge but
text-enumerable. The graph's recall advantage is gated by
**text-enumerability, not raw site count**. The economics still invert at
equal recall: $3.85–$5.46 and up to 55 turns, versus $0 and one turn. (A first
Haiku-text attempt exhausted a 20-minute budget without answering at all.)

---

## Cross-language

The same protocol, three more languages:

- **Go** (Grafana, 93 sites): engine ceiling 1.000/1.000. Haiku G\* **1.000**
  in 5 turns/$0.10; local 30B **1.000** in 1 turn/$0 — versus historical
  Haiku-text 0.817 with real variance. Variance collapse is total.
- **TypeScript** (TypeORM `Driver.escape`, 37 sites): a controlled
  ceiling-raise experiment. The engine was improved from 0.540 to 0.946 recall
  with models, prompts, and task frozen — and both the Haiku and local-30B G\*
  arms moved in lockstep to exactly the new ceiling (0.946/0.761). The tool is
  the variable; the model just relays. Haiku-text (0.568, 36 turns) is beaten
  on both axes.
- **Python** (Django `quote_name`, 32 sites): engine 1.000/0.865; Haiku and
  local-30B G\* at the ceiling.

---

## Free agentic coding, on the strength of the graph: Mason (experimental)

The tier-invariance result has a practical consequence worth testing
end-to-end: if completeness lives in the engine, a **free local model**
should be able to do real agentic coding. [Mason]({{ '/mason/' | relative_url }})
is our experimental CLI built to test exactly that — Prism baked into the
harness, any model on top. The scenarios, oracle-scored like everything
else on this page:

| Scenario | Local model, $0 | Result |
|---|---|---|
| Change-impact, jackson (8 sites incl. indirect callers) | qwen3-coder:30b via Mason | **recall 1.00** (agent-scored, all 8 sites) |
| Change-impact, Guava (310 sites) | qwen3-coder:30b | **0.997** — the engine ceiling, **1 agent turn** |
| Change-impact, Grafana Go (93 sites) | qwen3-coder:30b | **1.000**, 1 turn |
| Change-impact, Django Python (32 sites) | qwen3-coder:30b | **1.000** recall, 1 turn |
| End-to-end rename: plan → 24 edits applied → `go build` verified | local 14B via Mason | build green |

The control that makes this meaningful: the **same local model driving
general-purpose CLIs without task-shaped graph operations scored 0–1 out of
9** on the same task family
([AB-LOCAL-CLIS](https://github.com/provasign/research/blob/main/harness/AB-LOCAL-CLIS.md)).
The model didn't change — the tool altitude did. Mason is experimental and
says so; the numbers above are what it has proven so far.

---

## We keep benchmarking Prism against other tools — transparently

Correctness claims decay unless they are continuously tested, so we run an
ongoing program of benchmarking Prism against other open-source code-context
tools, under the same discipline as everything above: same independent
oracles, same scorer, same corpora, each tool queried through its
**strongest** surface, its own goals stated fairly, and every raw run
published.

The first entry is [CodeGraph](https://github.com/colbymchenry/codegraph),
an open-source tree-sitter code graph (30+ languages, one-call `explore`
context) built for context-delivery *efficiency* — a different, legitimate
goal from Prism's completeness-first design. That difference in goals is
exactly what makes it informative to measure: it isolates what **type
resolution** buys over **name resolution** when the question is "every site
this change breaks."

**Engine ceiling, 10 tasks, 4 languages, blast radius 8→310 sites:**

| | Prism | CodeGraph (`explore`) |
|---|---:|---:|
| **mean recall** | **0.99** | 0.52 |
| java (n=7) | 0.997 | 0.46 |
| go (n=1) | 1.00 | 1.00 — a genuine tie (direct-name dispatch; the control) |
| ts (n=1) | 0.95 | 0.73 |
| py (n=1) | 1.00 | 0.25 |

The reading is about the *mechanism*, not a ranking: where dispatch is
direct-name, name resolution ties type resolution. The gap opens only where
type resolution is load-bearing — overloads, wide subtype closures, callers
not named after the target. Any name-resolution graph, ours included if we
built one, would show the same distribution.

**The same contrast, with an agent in the loop** (same agent, same task,
arms differ only in the tool) — recall to reach a complete change-set, and
the cost of getting there:

| Tier | Prism | tree-sitter graph | grep baseline |
|---|---|---|---|
| Local 30B ($0) | **1.00** | — (see Haiku) | — |
| Haiku | **1.00** · 3 turns · $0.04 | 0.00 · 31 turns · $0.33 | 0.75 |
| Opus | **1.00** · 3 turns · $0.14 | 1.00 · 23 turns · $2.38 | 0.62 |

The pattern is the study's central result reproduced externally: over a
type-resolved graph at task altitude, completeness is a **tool** property —
it holds down to a free model. Over a name-resolved graph it is a **model**
property — reachable, but only by a frontier model spending 8× the turns and
24× the tokens re-deriving what the graph didn't resolve.

Honest scope: CodeGraph does not claim compiler-grade completeness, and it
is ahead of Prism on language breadth and framework-routing hints. Full
fairness protocol, per-task tables, efficiency-next-to-recall measurements,
and repro:
[AB-CODEGRAPH.md](https://github.com/provasign/research/blob/main/harness/AB-CODEGRAPH.md).
As we benchmark further tools, results land in the same place, under the
same rules.

---

## What we measured and refuse to cite

Two experiments produced headline-looking numbers we publish but will not
use as evidence — in either direction:

- **SWE-bench Verified A/B**: the baseline "resolved" 75% — because 9/20
  tasks reproduce the merged human fix with 100% exact added-line overlap.
  That measures training-data contamination, not tooling
  ([details](https://github.com/provasign/research/blob/main/harness/SWEBENCH-AB-RESULTS.md)).
- **PR-replay mining**: automatic task mining from real merged PRs pollutes
  ground truth; strict gates collapse the yield to zero in our sample
  ([details](https://github.com/provasign/research/blob/main/harness/PR-REPLAY-FINDINGS.md)).

---

## Scale

Measured on a Grafana monorepo worktree — 18,901 indexed files (~14.7k
Go/TypeScript sources, 1.4 GB), Apple M5 Pro, 24 GB:

Typical repos first (grove v0.17.2, Apple M5 Pro):

| Repo | Files | Cold index | One-file delta | No-op rescan | Peak RSS |
|---|---|---|---|---|---|
| gin (Go) | ~100 | 2.1 s | 1.9 s | <1 s | 90 MB |
| jackson-databind (Java) | 1.2k | 7.3 s | 2.8 s | 0.6 s | ~0.5 GB |
| TypeORM (TS) | 3.2k | 4.9 s | 3.0 s | <1 s | 0.6 GB |
| Grafana monorepo (Go+TS) | 18.9k | ~60 s | 13.1 s | 4.3 s | 2.1 GB |

And the monorepo detail:

| Operation | Measured (grove v0.17.2, Grafana 18.9k files) |
|---|---|
| Cold index — complete graph, deterministic | ~60 s (98,067 symbols, 1,468,951 edges) |
| No-op rescan (nothing changed) | 4.3 s |
| Delta after a one-file change | 13.1 s, incl. re-analyzing the changed package + its reverse importers |
| `change-impact` query, end-to-end CLI | ~4 s |

**Hardware:** any 4-core machine with 8 GB RAM handles repos up to a few
thousand files comfortably; 20k-file monorepos want 16 GB (2 GB peak for the
indexer alone, alongside your editor and agent). Parallel phases cap at 8
workers, so extra cores beyond that go unused. In persistent MCP sessions
the graph stays warm in memory — delta costs apply to one-shot CLI runs.

Two honesty notes. First, earlier versions reported a 33 s cold index — that
number was real but the graph was silently incomplete: a 5-second native-
analyzer timeout was dropping ~610k native edges on a repo this size. v0.17.0
sizes the analyzer budget to the repo, scopes delta re-analysis to changed
packages plus their reverse importers, and carries unaffected packages'
facts forward. Second, builds are now **bit-perfect deterministic**: repeated
cold builds produce byte-identical graphs, and an edit-then-revert cycle
converges exactly to the cold baseline — verified by hashing all 1.47M edge
rows. Queries never trigger a rebuild; sessions stay warm.

---

## What we do not claim

- **Small, greppable tasks are a tie.** On 8–38-site tasks with distinctive
  names, text search matches the graph at every tier (Go replicated this; so
  did Commons Collections). The graph wins when completeness requires
  type-level disambiguation or inheritance traversal — or when you care about
  the 20–60× turn count difference at equal recall.
- **The engine has a measured ceiling, not perfection.** Deterministic
  engine-only scoring: mean recall 0.993, precision 0.948 on the Java corpus;
  0.80 precision on one overload-ambiguous task. Every residual is visible,
  attributable, and fixable in one place — that is the point of doing the
  traversal in a tool.
- **The study measured tool classes, not a market.** T is what agentic grep
  agents do; G is what LSP/primitive code-intel servers expose; G\* is
  Prism. The ongoing cross-tool program above measures specific tools under
  the same protocol — each through its strongest surface, with its own goals
  stated — to test the *mechanism*, not to rank products.
- **Relay discipline matters.** One capable model (Sonnet) re-processed the
  engine's solved output through its own grep/awk pipeline and corrupted it
  (0.961 recall, 0.909 precision); removing the text-search escape hatch
  restored the exact engine ceiling. Prism's steering and tool descriptions
  encode this.

---

## Reproduce it

```sh
git clone https://github.com/provasign/research
cd research/harness
# tasks/, runs/, scoring, and per-language oracles are all in the repo
python agg_jackson.py        # re-aggregate the shipped run logs
```

The [research README](https://github.com/provasign/research#readme) has the
full pipeline: oracle build, task generation, arm runners for Claude Code /
Codex / local models, and the mandatory Java rescoring step.

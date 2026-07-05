---
title: Benchmarks
layout: default
nav_order: 6
description: "Measured recall, cost, and turns for agentic grep vs graph primitives vs task-shaped operations — same tasks, same independent oracles."
permalink: /benchmarks/
---

# Benchmarks — measured, not vibes

Every number on this page comes from a controlled, paired study: same task,
same repository, same model — only the tool guidance changes. Answers are
scored against **independent oracles** (Go: SSA/VTA; Java: a Spoon
type-resolution oracle; TypeScript: a ts-morph compiler oracle), never against
Prism's own engine. The full harness, tasks, run logs, and scoring code are
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
- **We measured tool classes, not competitor products.** T is what agentic
  grep agents do; G is what LSP/primitive code-intel servers expose; G\* is
  Prism. We have not benchmarked other vendors' tools by name.
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

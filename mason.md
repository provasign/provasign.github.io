---
title: Mason
layout: default
nav_order: 4
description: "A coding agent for any model — local, Anthropic, or OpenAI — with the code graph and evidence trail built into the harness, not the prompt."
permalink: /mason/
---

# Mason — the harness-first coding agent

**The problem:** coding agents are built for frontier models. Point one at a
local 30B and it forgets steering, re-types tool output lossily, re-derives
solved traversals through grep, and claims success on work it never did.
Prompts don't fix any of that — the failure is in what the model is *allowed*
to do, not what it's told.

**What Mason does:** it makes the behaviors that keep agents accurate and
cheap **properties of the harness** — structurally enforced, model-blind. The
result, measured: a **free local model completes change-impact and rename
tasks at the same engine ceiling as a frontier model**
([benchmarks]({{ '/benchmarks/' | relative_url }})).

```sh
mason "Rename the Status method of the ResponseWriter interface to StatusCode.
       Apply the plan including ambiguous edits, then verify with 'go build ./...'"
```

That task runs end-to-end — complete type-resolved rename plan, 24 edits
applied, build verified — on a local model at $0.

---

## Why a harness instead of steering

Measured across model tiers ([research](https://github.com/provasign/research)),
steered agents fail in two ways prompts cannot fix: they **relay** engine
results lossily (re-typing a site list drops sites), and they **re-derive**
solved traversals through grep. Mason makes both structurally impossible:

| Harness property | What it enforces |
|---|---|
| **Payload isolation** | Graph-operation payloads (site lists, edit plans) render directly to *you*; the model receives only counts and flags. It cannot drop what it never holds. |
| **Invocation wall** | Tasks shaped like measured graph wins (renames, signature changes, "all callers", dead code) are walled onto the graph tools for their first turn. |
| **Harness-applied edits** | Rename plans are applied by Mason with per-line drift checks — never re-typed by the model. |
| **Honesty guard** | If a task asked for a change and the working tree is untouched when the model claims success, the claim is rejected. |
| **Secret redaction** | Every tool result is scanned before it reaches the model; credentials become `[REDACTED:kind]`, itemized by kind. |
| **Plan mode** | `--plan` makes the session read-only *in the harness* — mutating tools are refused, not discouraged. |

Grounding, refusal handling, deterministic compaction, permission policies,
per-task checkpointing with `/undo`, hooks, and LSP diagnostics at edit time
are harness properties too — the [README](https://github.com/provasign/mason#readme)
has the full list.

---

## Any model

```sh
mason --model sonnet "task…"                 # friendly names: sonnet · haiku · opus · fable · gpt
mason --model ollama:qwen3-coder:30b "task…" # local via Ollama
mason --model lmstudio:qwen2.5-coder-32b "…" # LM Studio
mason --model oai:http://localhost:8000#m "…"# any OpenAI-compatible server
```

`/model` shows one numbered list — installed local models, downloadable
local models (filtered by your machine's memory, one-keypress download,
including installing Ollama itself), a curated API shortlist, and the live
model list from any vendor you've keyed. Picking an API model without a
stored key starts a guided setup; keys land only in the OS keychain.

**Local models are first-class, not a fallback.** The measured result the
design targets: task-shaped graph operations make completeness
**tier-invariant** — recall 1.00 from a free qwen3-coder:30b up to a
frontier model, across four languages
([benchmarks]({{ '/benchmarks/' | relative_url }})).

---

## Installation

{% include install.html repo="provasign/mason" curl="curl -fsSL https://raw.githubusercontent.com/provasign/mason/main/install.sh | bash" %}

```sh
# or via Go
go install github.com/provasign/mason/cmd/mason@latest
```

Then, in any repo:

```sh
mason            # full-screen TUI: transcript, markdown, inline diffs, autocomplete
mason "task…"    # one-shot
mason --json --yes "task…"   # CI: one JSON object on stdout
```

---

## Where it fits

Mason is the **agent layer** of the family: it drives any model and consumes
[Prism]({{ '/prism/' | relative_url }})/[Grove]({{ '/grove/' | relative_url }})
natively (the graph is baked in — no MCP setup, no steering files) and logs an
evidence trail through [Shale]({{ '/shale/' | relative_url }}) when it's on
PATH. Every layer works standalone.

[Get Mason on GitHub →](https://github.com/provasign/mason){: .btn .btn-primary }

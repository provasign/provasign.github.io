---
title: Prism
layout: default
nav_order: 3
description: "Graph-ranked context delivery for AI coding agents — callers, tests, and blast radius without a dozen file reads."
permalink: /prism/
---

# Prism — the context your agent was about to spend 40k tokens finding

**The problem:** watch an agent work and you'll see the same ritual on every
task: grep for a symbol, open the file, open the caller, open the test, open
another file that turned out to be irrelevant… Each read costs tokens and
time, and the agent still misses the test that defines the behavior it's
about to change.

**What Prism does:** it answers the *follow-up* questions in one call. Give
it a task and an anchor symbol; it returns the code, callers, callees, tests,
docs, and coverage gaps — ranked by relevance to the task and packed into a
token budget.

## What that looks like

```sh
prism query "fix auth rate limit tests" \
  --terms RateLimiter --include graph,tests,coverage_gaps --format text
```

One command returns: the `RateLimiter` source, the three places that call it,
the two tests that pin its contract, and a note that `RefillRate` has no
direct test coverage. That's the context an agent needs to change the code
*safely* — not just the lines that matched a grep.

The division of labor is deliberate:

- **`rg`/`grep`** — find the first anchor. Fast, cheap, perfect for that.
- **Prism** — everything after the anchor: *what calls this? what does it
  call? which tests define the contract? what's in the blast radius? what
  nearby code has no tests at all?*

## Built for how agents actually run

- **MCP and CLI, same engine.** `prism init . --mode both` registers MCP
  tools (`prism_query`, `prism_read`, `prism_lookup`) for the main agent and
  leaves the CLI for subagents and CI scripts that don't inherit the MCP
  session.
- **Token-aware by design.** Progressive disclosure serves full source only
  when needed, signatures (~15% of tokens) or references (~3%) otherwise.
  Repeat reads of an unchanged file collapse to a ~10-token SHA pointer.
- **`--format text`** gives agents plain, source-like context with short
  headers — no JSON wrappers inflating the bill.
- **Zero infrastructure.** Grove (the code graph) is embedded in the Prism
  binary: no daemon, no port, no token, no server.

## Setup

```sh
prism init . --mode both
prism index .
```

`prism init` detects your installed tools and writes the right config for
Claude Code, Cursor, VS Code Copilot, Codex CLI, Windsurf, and Zed, plus
steering instructions so agents know when to reach for it. Indexing 5,000
files takes seconds; the graph updates incrementally as files change.

## Where it fits with the other tools

Prism is the **context layer**. [Shale]({{ '/shale/' | relative_url }}) is
the **evidence layer** — what the agent did, on the PR. [Grove]({{ '/grove/'
| relative_url }}) is the **graph engine** both build on, available directly
when you want the graph itself. Use any of them alone; they need no shared
account or server.

[Get Prism on GitHub →](https://github.com/provasign/prism){: .btn .btn-primary }

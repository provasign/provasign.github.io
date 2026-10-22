---
title: Prism
layout: default
nav_order: 2
description: "Semantic change intelligence for coding agents: change impact, edit-ready context, and diff verification. Answers questions; never edits code."
permalink: /prism/
---

# Prism

Prism gives coding agents semantic change intelligence before they edit. It combines repository text search with a typed code graph and returns task-shaped answers: the complete method family, resolved callers, edit-ready source, and every known site a diff missed.

Prism answers questions. It never edits code; the agent makes every change.

It runs locally as one binary and embeds [Grove]({{ '/grove/' | relative_url }}). Agents reach it one of two ways: as an MCP server, or through the `prism` command in their shell (`prism init --interface cli`).

## Start in one command

```sh
brew install provasign/tap/prism
cd your-repo
prism init .
```

You can also use the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash

# Pin the current release
VERSION=v1.0.1 curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
```

`prism init` writes `prism.yaml` and agent instructions for the agents you pick: Claude Code, Codex, Cursor, Copilot (VS Code), Gemini CLI, OpenCode, and Windsurf. It asks which interface to use. MCP (the default) registers a project-local server. CLI registers no server; agents run `prism` in their shell. To choose without a prompt:

```sh
prism init --harness claude,codex --interface cli .
```

Indexing happens automatically on first use and updates incrementally.

## One route for each question

| Question | Route |
|---|---|
| Where is this name or text? | `prism search` |
| What source does this task need? | `prism query` |
| What must change with this method? | `prism change-impact` |
| What are the exact rename edits? | `prism rename-plan` |
| Which types lack a new interface member? | `prism missing-implementations` |
| Did this diff miss a required site? | `prism verify` |
| Did this diff cross a forbidden boundary? | `prism arch` |

```sh
prism search QueryData --scope text --exhaustive --files-only
prism change-impact 'QueryDataHandler.QueryData' --format text
prism verify --base main --format text
```

Exhaustive search returns a compact inventory of exact files and enclosing symbols. `change-impact` returns the declaration, override and implementation family, sibling contracts, and resolved callers. `verify` turns that semantic set into a diff completeness gate.

## Current measured result

Prism 1.0.0 against native Claude Code (measured on v0.87.39, which 1.0.0 matches apart from CLI help text; Sonnet 5.5, CLI interface, one run per cell):

| | Native | Prism | Prism / native |
|---|---:|---:|---:|
| Change work, 32 tasks: solved | 31 / 32 | 32 / 32 | |
| Change work: task cost | $0.0646 | $0.0492 | 0.76× |
| Change work: tool calls | 6.8 | 4.4 | 0.65× |
| Bug fixes, 40 issues (v0.87.37): solved | 23 / 40 | 25 / 40 | |
| Bug fixes: task cost | $0.0520 | $0.0477 | 0.92× |

The bug-fix solve difference is within run-to-run noise. Startup cost per session is 1.03× native.

[See the full tables, setup, and limits.]({{ '/benchmarks/' | relative_url }})

## Designed for reliable use

- **Deterministic graph operations.** The engine solves traversal and returns the same result for the same repository state.
- **Explicit completeness.** Results state when evidence is closed, project-local, heuristic, stale, or unsupported.
- **Edit-ready delivery.** `prism query` returns line-numbered source around named anchors instead of another list of pointers.
- **Session deduplication.** Re-reading an unchanged file through MCP returns a short pointer instead of the content.
- **Local operation.** Code and indexes stay in the working environment; the default MCP transport is stdio.
- **CI gates.** `prism verify` and `prism arch` exit nonzero when their checks fail.

## Language support

Prism indexes Go, TypeScript/TSX, JavaScript/JSX, Python, Java, Rust, C/C++, C#, PHP, Swift, Kotlin, Objective-C, COBOL, and JCL through the embedded Grove engine. Semantic depth depends on the language and on the native toolchain available in the repository. COBOL and JCL have a regression-tested graph; their accuracy is not yet independently scored. `grove doctor .` reports the full per-language resolution tier and limitations breakdown.

## Learn more

- [GitHub repository](https://github.com/provasign/prism)
- [Reproducible research](https://github.com/provasign/research)
- [Grove engine]({{ '/grove/' | relative_url }})
- [Benchmarks]({{ '/benchmarks/' | relative_url }})

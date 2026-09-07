---
title: Prism
layout: default
nav_order: 2
description: "Semantic change intelligence for coding agents: complete impact, edit-ready context, and diff verification."
permalink: /prism/
---

# Prism

Prism gives coding agents semantic change intelligence before they edit. It combines repository text search with a typed code graph and returns task-shaped answers: the complete method family, resolved callers, edit-ready source, and every known site a diff missed.

It runs locally as one binary, embeds [Grove]({{ '/grove/' | relative_url }}), and exposes both a CLI and a focused MCP interface.

## Start in one command

```sh
brew install provasign/shale/prism
cd your-repo
prism init .
```

You can also use the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash

# Pin the current release
VERSION=v0.72.0 curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
```

`prism init` creates the local configuration, registers MCP for detected clients, and writes concise agent instructions. Indexing happens automatically on first use and updates incrementally.

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

In the latest nine-task paired Sonnet release-gate sample, Prism improved mean recall from 0.683 to 0.998 and mean precision from 0.770 to 0.955. Total estimated cost fell from $3.23 to $1.28, or 0.40× the native-tool total.

| Aggregate across nine tasks | Native tools | Prism |
|---|---:|---:|
| Mean recall | 0.683 | **0.998** |
| Mean precision | 0.770 | **0.955** |
| Total estimated cost | $3.23 | **$1.28** |

Each cell is one fresh run. Repeated trials are reported separately. Three paired Jackson `JsonNode.get` trials moved recall from 0.625 to 1.000 while reducing mean turns from 30.0 to 8.3 and mean cost from $0.404 to $0.205.

The hardest current case is Grafana's `QueryData` interface, declared in an external Go SDK and implemented implicitly by many unrelated local types. The audited oracle contains 70 sites. One deterministic Prism operation returns the full local family, and three fresh agent trials each reached 1.0 recall.

[See the full table, methods, raw evidence, and limitations.]({{ '/benchmarks/' | relative_url }})

## Designed for reliable use

- **Deterministic graph operations.** The engine solves traversal and returns the same result for the same repository state.
- **Explicit completeness.** Results state when evidence is closed, project-local, heuristic, stale, or unsupported.
- **Edit-ready delivery.** `prism query` returns line-numbered source around named anchors instead of another list of pointers.
- **Session deduplication.** Re-reading an unchanged file through MCP returns a compact content pointer.
- **Local operation.** Code and indexes stay in the working environment; the default MCP transport is stdio.
- **CI gates.** `prism verify` and `prism arch` exit nonzero when their checks fail.

## Language support

Prism indexes Go, TypeScript/TSX, JavaScript/JSX, Python, Java, Rust, C/C++, C#, and PHP. Semantic depth depends on language support and the native toolchain available in the repository. `prism doctor .` reports the active capability and evidence tier.

## Learn more

- [GitHub repository](https://github.com/provasign/prism)
- [Reproducible research](https://github.com/provasign/research)
- [Grove engine]({{ '/grove/' | relative_url }})
- [Benchmarks]({{ '/benchmarks/' | relative_url }})

---
title: Grove
layout: default
nav_order: 4
description: "A persistent code graph for your repository — impact, tests, and dependencies, queryable by humans, tools, and agents."
permalink: /grove/
---

# Grove — your codebase as a graph, not a pile of files

**The problem:** the questions that actually matter before changing code are
graph questions, and neither grep nor a language server answers them: *what
breaks — across the whole repo — if this function changes? Which tests cover
it, directly or transitively? What's the dependency chain from this file?*

**What Grove does:** it parses your repository (Tree-sitter, 11 languages,
native semantic analyzers for the big ten) into a persistent SQLite graph —
symbols, calls, imports, tests, 8 edge types — and keeps it live with delta
indexing. Files whose content hasn't changed are never re-parsed.

## Ask it things

```sh
grove index .
grove symbols AuthService
grove impact internal/auth/service.go::AuthService.Login
grove tests  internal/auth/service.go::AuthService.Login
```

`impact` walks the call graph to show blast radius. `tests` returns the tests
that pin a symbol's behavior — including transitive coverage. Both answer in
milliseconds from the on-disk graph (BFS depth-3 on 50k nodes in under 30ms).

## Three ways in

| Surface | For |
|---|---|
| **CLI** | humans, scripts, CI |
| **MCP stdio** (`grove mcp .`) | any MCP-capable agent — 8 tools including query, impact, deps, tests |
| **Embedded Go API** (`pkg/grove`) | your own tools — this is how [Prism]({{ '/prism/' | relative_url }}) and Fuse use it, in-process, no daemon |

Everything lives in `.grove/grove.db` — one SQLite file. Back it up, copy it,
or delete it to force a full reindex. No server, no port, no token.

Indexing respects `.gitignore` and `.groveignore`, skips dependency and build
directories, and avoids secret-bearing filenames and key extensions.

[Get Grove on GitHub →](https://github.com/provasign/grove){: .btn .btn-primary }

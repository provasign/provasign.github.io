---
title: Grove
layout: default
nav_order: 5
description: "Local multilingual code graph for impact analysis, incremental indexing, and embedded tooling."
permalink: /grove/
---

# Grove

Grove is the local semantic graph under Prism. It parses a repository, stores symbols and typed relationships in SQLite, and answers deterministic questions about callers, implementations, dependencies, tests, and change impact.

Most coding-agent users should install [Prism]({{ '/prism/' | relative_url }}), which embeds Grove and presents a smaller task-focused interface. Grove is available directly for tool builders who need the CLI, MCP server, or Go API.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash

# Pin the current release
VERSION=v0.63.25 curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash
```

```sh
grove init .
grove index .
grove status .
```

## What Grove models

- symbols and file structure
- imports and dependencies
- resolved calls
- type use, inheritance, implementation, and override relationships
- test relationships
- component and diff evidence consumed by higher-level tools

Grove supports Go, TypeScript/TSX, JavaScript/JSX, Python, Java, Rust, C/C++, C#, PHP, Swift, Kotlin, Objective-C, COBOL, and JCL. Tree-sitter provides structural extraction. Native analyzers enrich the graph when the repository toolchain is available. `grove doctor` reports each language's resolution tier and known limits.

## Task operations

```sh
grove symbols QueryData .
grove impact internal/query/service.go .
grove change-impact 'QueryDataHandler.QueryData' .
grove missing-implementations 'Handler.Handle' .
grove rename-plan 'Service.Run' Execute .
grove certify change.diff .
```

`change-impact` returns the declaration, method family, contracts, and resolved callers. It supports local Go implementations of compatible interface methods declared in dependencies. Incremental indexing refreshes only changed files and affected packages while preserving byte-identical graph output.

## Integration

- **Go package:** embed `github.com/provasign/grove/pkg/grove`
- **CLI:** local automation and diagnostics
- **MCP:** `grove mcp .` over stdio
- **Prism:** token-budgeted source delivery and focused change operations

Grove opens no network listener. Its index lives in `.grove/grove.db`, honors repository ignore rules, and skips common dependency, build, cache, and secret-bearing paths.

## Evidence

Call-edge accuracy is CI-gated against each language's compiler or runtime ground truth on pinned repositories. Grove v0.63.25, selected rows (precision / recall):

| Language | Corpus | Ground truth | Precision | Recall |
|---|---|---|---:|---:|
| Go | gin / cobra | SSA + VTA | 0.979 / 0.995 | 0.997 / 1.000 |
| Java | commons-lang / commons-io | javac + javap | 1.000 / 1.000 | 1.000 / 1.000 |
| TypeScript | socket.io / p-queue | TypeScript compiler API | 0.937 / 0.959 | 0.992 / 1.000 |
| Python | flask | pytest trace (dynamic) | 0.896 | 0.787 |
| PHP | PHP-Parser | Xdebug trace (dynamic) | 0.922 | 0.683 |

COBOL and JCL have a regression-tested graph; their accuracy is not yet independently scored. All twelve scored languages are on the [benchmarks page]({{ '/benchmarks/' | relative_url }}#engine-accuracy-grove-v06325).

- [GitHub repository](https://github.com/provasign/grove)
- [Prism]({{ '/prism/' | relative_url }})
- [Research](https://github.com/provasign/research)

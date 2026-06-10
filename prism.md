---
title: Prism
layout: default
nav_order: 3
description: "Graph-ranked context delivery for AI coding agents."
permalink: /prism/
---

# Prism

Prism is the secondary open-source product from the Provasign org.

It turns a task plus precise anchor terms into the code, callers, callees,
tests, docs, and coverage gaps an agent needs to make a change safely. It is
the agent-context layer: use `rg` to find the first anchor, then use Prism to
retrieve the surrounding graph-aware context.

## Typical Use

```sh
prism init . --mode both
prism index .
prism query "fix auth rate limit tests" --terms RateLimiter --include graph,tests,coverage_gaps --format text
```

Prism embeds Grove in-process. There is no separate Grove daemon, token, or
server URL in the normal path.

## Repository

[Read the Prism README on GitHub ->](https://github.com/provasign/prism#readme){: .btn .btn-primary }

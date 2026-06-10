---
title: Documentation
layout: default
nav_order: 1
description: "Documentation map for Shale, Prism, and Grove."
permalink: /docs/
---

# Documentation

This site documents the open-source toolchain in the `provasign` GitHub
organization:

| Project | Role | Status |
|---|---|---|
| **Shale** | Agent PR evidence: intent capture, session evidence, local checks, and pull-request cards | Primary product, Apache-2.0 |
| **Prism** | Graph-ranked context delivery for AI coding agents | Secondary product, MIT |
| **Grove** | Persistent code graph and indexing engine for direct graph use or embedded tools | Graph engine, MIT |

Provasign is the GitHub organization for these tools. Start with Shale.

---

## Start Here

| Goal | Link |
|---|---|
| Add agent PR evidence to a repo | [Shale]({{ '/shale/' | relative_url }}) |
| Give agents graph-ranked context | [Prism]({{ '/prism/' | relative_url }}) |
| Use the code graph directly | [Grove]({{ '/grove/' | relative_url }}) |
| Read the Shale source/docs | [Shale repository](https://github.com/provasign/shale#readme) |

---

## Install Shale

```sh
brew tap provasign/shale
brew install shale
cd your-repo
shale init
```

If Homebrew asks you to trust the tap:

```sh
brew trust --formula provasign/shale/shale
brew install shale
```

No account, token paste, GitHub App, hosted server, or background service is
required.

---

## What Shale Adds to a PR

- the agent's stated intent
- the agent/model/session metadata available locally
- changed files with hook evidence or git-derived fallback evidence
- checks observed during the agent session
- explicit gaps where files changed without session evidence
- a neutral PR card that never blocks a merge by default

Shale is intentionally advisory and fail-open. It gives reviewers better
evidence without turning local agent workflows into a hosted compliance product.

---

## Repositories

- [provasign/shale](https://github.com/provasign/shale) — primary product
- [provasign/prism](https://github.com/provasign/prism) — secondary product
- [provasign/grove](https://github.com/provasign/grove) — graph engine

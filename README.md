---
title: Shale Documentation
layout: default
nav_order: 1
description: "Shale documentation, with links to Prism and Grove."
permalink: /docs/
---

# Shale Documentation

Start here if you want agent-authored PRs to carry intent, local evidence, and
a reviewer-ready PR card.

| Project | Role | Status |
|---|---|---|
| **Shale** | Agent PR evidence: intent capture, session evidence, local checks, and pull-request cards | Primary product, Apache-2.0 |
| **Prism** | Graph-ranked context delivery for AI coding agents | Secondary product, Apache-2.0 |
| **Grove** | Persistent code graph and indexing engine for direct graph use or embedded tools | Graph engine, Apache-2.0 |

---

## Start Here

| Goal | Link |
|---|---|
| Add agent PR evidence to a repo | [Shale]({{ '/shale/' | relative_url }}) |
| Full setup walkthrough | [Getting started](https://github.com/provasign/shale/blob/main/docs/getting-started.md) |
| Something looks off | [Troubleshooting](https://github.com/provasign/shale/blob/main/docs/troubleshooting.md) |
| See real cards on real PRs | [Live demo pull requests](https://github.com/provasign/shale-test-bed/pulls?q=is%3Apr) |
| Give agents graph-ranked context | [Prism]({{ '/prism/' | relative_url }}) |
| Use the code graph directly | [Grove]({{ '/grove/' | relative_url }}) |

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

---
title: Provasign Documentation
layout: default
nav_order: 1
description: "Documentation for Prism, Shale, and Mason."
permalink: /docs/
---

# Provasign Documentation

Prism and Shale are the core open-source projects. Mason is the incubating
reference agent that integrates both. Grove is shared engine infrastructure,
not a fourth product users must adopt.

| Project | Role | Status |
|---|---|---|
| **Prism** | Semantic change intelligence for developers, coding agents, and CI | Core project, Apache-2.0 |
| **Shale** | Agent intent, session evidence, local checks, and pull-request cards | Core project, Apache-2.0 |
| **Mason** | Reference coding agent with Prism and Shale built into the harness | Incubating, Apache-2.0 |

---

## Start Here

| Goal | Link |
|---|---|
| Understand the complete impact of a code change | [Prism]({{ '/prism/' | relative_url }}) |
| Add agent PR evidence to a repo | [Shale]({{ '/shale/' | relative_url }}) |
| Run the integrated reference agent | [Mason]({{ '/mason/' | relative_url }}) |
| Full setup walkthrough | [Getting started](https://github.com/provasign/shale/blob/main/docs/getting-started.md) |
| Something looks off | [Troubleshooting](https://github.com/provasign/shale/blob/main/docs/troubleshooting.md) |
| See real cards on real PRs | [Live demo pull requests](https://github.com/provasign/shale-test-bed/pulls?q=is%3Apr) |
| Review published performance evidence | [Benchmarks]({{ '/benchmarks/' | relative_url }}) |

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

- [provasign/prism](https://github.com/provasign/prism) — core project
- [provasign/shale](https://github.com/provasign/shale) — core project
- [provasign/mason](https://github.com/provasign/mason) — incubating reference agent
- [provasign/grove](https://github.com/provasign/grove) — shared semantic graph engine

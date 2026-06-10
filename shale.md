---
title: Shale
layout: default
nav_order: 2
description: "Agent PR evidence: intent capture, session evidence, local checks, and pull-request cards."
permalink: /shale/
---

# Shale

Shale is the primary open-source product from the Provasign org.

It records what an AI coding agent was asked to do, what it touched, and what
checks it ran, then renders that evidence as a pull-request card.

## Install

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

## Why It Exists

Agent-written PRs need more than a diff. Reviewers need to know:

- What was the agent asked to do?
- Which files were observed in the agent session?
- What local checks ran before the PR?
- Which changed files have no evidence?
- Is this advisory evidence or a blocking gate?

Shale answers those questions without requiring an account, hosted service,
GitHub App, token paste, or custom server.

## How It Works

```text
agent task
  -> shale intent
  -> hook/CLI evidence capture
  -> shale done
  -> shale finalize on push
  -> shale render in CI
  -> PR card
```

Evidence is redacted before persistence and committed under `.shale/`, so it
travels with fork PRs and same-repo PRs alike. The default GitHub Action renders
the card with the repo's own `GITHUB_TOKEN`.

## Repository

[Read the Shale README on GitHub ->](https://github.com/provasign/shale#readme){: .btn .btn-primary }

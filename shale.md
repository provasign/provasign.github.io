---
title: Shale
layout: default
nav_order: 2
description: "Agent PR evidence: intent capture, session evidence, local checks, and pull-request cards."
permalink: /shale/
---

# Shale — every agent PR explains itself

**The problem:** your team ships AI-agent code every day, but reviewers still
get what they always got — a diff. The prompt that produced it, the files the
agent actually touched, the tests it ran before pushing: all of that lives on
the author's laptop and dies there. So reviewers re-derive context the agent
already had, approve on faith, or slow everything down asking "what was this
supposed to do?"

**What Shale does:** it records the agent session — intent, files touched,
commands run, model and cost — and renders it as a card on the pull request.
The evidence travels with the code. The reviewer reads the card, then the
diff.

<img src="{{ '/assets/images/shale-demo.svg' | relative_url }}"
     alt="A real Claude Code session with Shale: the agent declares intent, edits files, runs tests, reports done; git push commits the evidence"
     width="720" style="max-width:100%; border-radius:10px; margin: 8px 0 4px;">

*Every output line above is real — captured verbatim from a live session.*

## What lands on the PR

A card like [this one, on a live demo PR](https://github.com/provasign/shale-test-bed/pull/1):

> **🧾 Shale · 1 session · claude-code (claude-fable-5)**
> claude-fable-5 · 60k tokens · ~$0.67 · 2 iterations · < 1 min
>
> **Intent** — *Add rate limiting to the login endpoint.* Token bucket per
> client IP, 10 requests/min, in-memory. Return 429 with Retry-After.
>
> **Changed files (3) — all with session evidence**
>
> | File | Session | Notes |
> |---|---|---|
> | `internal/ratelimit/ratelimit.go` | ✅ 25f37dfc | new file |
> | `internal/ratelimit/ratelimit_test.go` | ✅ 25f37dfc | new file |
> | `main.go` | ✅ 25f37dfc | |
>
> **Checks recorded locally** — `go test ./...` ✅ passed
>
> *Advisory — CI is authoritative.*

And just as importantly, what the card shows when things are **less** tidy:

- a file changed with **no session evidence** → flagged, not hidden
- a **sensitive path** touched (dependency manifest, CI config, auth code) →
  bolded, kept above the fold
- evidence **edited after capture** → a tamper warning, and the affected text
  treated as unverified
- a PR with **no evidence at all** → an explicit "No shale for this PR" note
  instead of silence

The card's honesty about gaps is the feature. Reviewers learn to trust it
precisely because it never pretends to know more than it does.

## Five minutes, one person, whole team

```sh
brew install provasign/shale/shale
cd your-repo
shale init
git add . && git commit -m "chore: enable shale" && git push
```

`shale init` writes everything **into the repo** — agent steering, capture
hooks, evidence store, and the GitHub Action. Your teammates get wired
automatically on `git clone`. Nobody signs up for anything; there is no
server, no account, no GitHub App, no token to paste.

Teammates who haven't installed the CLI see nothing at all: the committed
hooks are self-guarding and stay silent until `shale` appears on their PATH.

## How it works, honestly

1. **The agent declares intent.** A steering block (in `CLAUDE.md`,
   `AGENTS.md`, `.cursorrules`, …) tells your agent to run
   `shale intent "<goal>"` before its first edit and `shale done` when
   finished. Works with any agent that can run a shell command.
2. **Hooks capture the session.** For agents with hook support (Claude Code
   today; Cursor, Codex, and Copilot configs ship inert and light up as
   adapters land), every file touch, command, and prompt streams into a local,
   **redacted** session log. No hooks? Shale falls back to git to derive the
   file list — and labels it as such on the card.
3. **Push finalizes.** A pre-push hook folds the session into
   `.shale/<session>.yaml` plus a SHA-256-pinned, prompts-only transcript and
   commits them. Fail-open: a Shale problem can never block your push.
4. **CI renders the card.** The GitHub Action reads the evidence and the diff
   through the API — it never checks out PR code — verifies the transcript
   hashes, and posts the card as a comment plus a neutral check.

## The questions your security team will ask

**Does prompt text leave the laptop?** No — period, in current builds.
Shale can capture the raw prompts developers type and redact them (secrets,
credentials, tokens) before committing a prompts-only transcript, but we
have **turned that off in the product** — a build-time flag, deliberately
not configurable — until we are confident the redaction layer handles
free-form human text and the regulatory questions around capturing raw
prompts are settled. Prompts stay in gitignored `.shale/local/` on the
laptop; committed evidence carries only a prompt count and an intent
integrity hash. Agent-authored text (intent, notes, commands) is redacted
before persistence (`full` / `redacted` / `hash-only` modes).

**Can the author fake the evidence?** Editing evidence after capture is
detected and flagged on the card (hash verification at render time).
Wholesale fabrication by a determined insider is explicitly out of scope for
v1 — and the card never claims otherwise. Honest labels (`hook-verified` vs
`git-derived`) are load-bearing.

**Can it block our merges?** No. The check is never `failure`, the pre-push
hook always lets the push through, and capture exits 0 on every error. Shale
is evidence, not enforcement.

**What does it phone home?** Nothing. No telemetry, no accounts, no network
calls from the laptop — enforced by test.

## Start here

- **[Getting started](https://github.com/provasign/shale/blob/main/docs/getting-started.md)** — the full walkthrough
- **[Live demo PRs](https://github.com/provasign/shale-test-bed/pulls?q=is%3Apr)** — happy path, coverage gaps, and the no-evidence nudge, on real PRs
- **[Troubleshooting](https://github.com/provasign/shale/blob/main/docs/troubleshooting.md)** — when something looks off
- **[Product & architecture](https://github.com/provasign/shale/blob/main/docs/product.md)** — design decisions, capture tiers, security model

[Get Shale on GitHub →](https://github.com/provasign/shale){: .btn .btn-primary }

---
title: Shale
layout: default
nav_order: 3
description: "Review evidence for AI-written code: intent, touched files, local checks, integrity signals, and explicit gaps on the pull request."
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
     alt="A real Claude Code session with Shale: the agent declares intent, edits files, runs tests, reports done — and done commits the evidence"
     width="720" style="max-width:100%; border-radius:10px; margin: 8px 0 4px;">

*Every output line above is real — captured verbatim from a live session.*

## What lands on the PR

A card like [this one, on a live demo PR](https://github.com/provasign/shale-test-bed/pull/1):

> **<img src="{{ '/assets/images/logo-icon.png' | relative_url }}" width="16" height="16" alt=""> Shale · 1 session · claude-code (claude-fable-5)**
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

{% include install.html repo="provasign/shale" formula="provasign/shale/shale" curl="curl -fsSL https://raw.githubusercontent.com/provasign/shale/main/install.sh | sh" %}

```sh
cd your-repo
shale init
git add . && git commit -m "chore: enable shale" && git push
```

<img src="{{ '/assets/images/shale-init.gif' | relative_url }}"
     alt="shale init in a fresh repo: steering, capture hooks, a consent prompt for the Claude Code allowlist, scaffold, workflow, pre-push hook"
     width="720" style="max-width:100%; border-radius:10px; margin: 8px 0 4px;">

`shale init` writes everything **into the repo** — agent steering, capture
hooks, evidence store, and the GitHub Action. Your teammates get wired
automatically on `git clone`. Nobody signs up for anything; there is no
server, no account, no GitHub App, no token to paste.

The one question it asks (real terminals only, default no): whether to
auto-approve the three shale evidence commands for Claude Code. Saying yes
writes a permissions allowlist — scoped to exactly `shale intent`,
`shale done`, and `shale note`, never a wildcard — into the committed
`.claude/settings.json`, so the whole team's agents stop hitting permission
prompts for evidence. It's visible in the bootstrap PR diff and
`shale uninstall --repo` removes it.

Teammates who haven't installed the CLI see nothing at all: the committed
hooks are self-guarding and stay silent until `shale` appears on their PATH.

**Repos with branch protection:** run `shale init` on a branch, open a
normal PR, merge it. The bootstrap PR won't have a Shale card — that's
expected, because the workflow doesn't exist on `main` yet. Every PR
after that merge gets a card. [Full guide →](https://github.com/provasign/shale/blob/main/docs/getting-started.md)

**Already using husky/lefthook or another PR bot?** Fine on both counts.
`init` never clobbers existing hooks (it honors `core.hooksPath` and names
the exact hook file if you want to chain `shale finalize --auto-commit`
into it) — and since evidence now publishes at `shale done`, agent sessions
don't depend on that hook at all; chaining only matters as the safety net
for sessions without a done. The card never touches comments posted by
other tools.

## How it works, honestly

1. **The agent declares intent.** A steering block (in `CLAUDE.md`,
   `AGENTS.md`, `.cursorrules`, …) tells your agent to run
   `shale intent "<goal>"` before its first edit and `shale done` when
   finished. Works with any agent that can run a shell command.
2. **Hooks capture the session.** For agents with hook support, every file
   touch, command, and prompt streams into a local, **redacted** session log.
   Claude Code and Codex are tested against real sessions today; Cursor and
   Copilot adapters are implemented but not yet validated against real
   payloads — [real payload samples welcome](https://github.com/provasign/shale/issues/4).
   No hooks? Shale falls back to git to derive the file list — and labels it
   as such on the card.
3. **`shale done` publishes.** The done call folds the session into
   `.shale/<session>.yaml` and commits it on the spot — the evidence commit
   exists before you push, so it always travels with the code. A pre-push
   hook remains as the safety net, finalizing any session that never got a
   `done` (interrupted agents, sessions an agent abandoned). Fail-open both
   ways: a Shale problem can never block your push.
4. **CI renders the card.** The GitHub Action reads the evidence and the diff
   through the API — it never checks out PR code — verifies the transcript
   hashes, and posts the card as a comment plus a neutral check.

## The questions your security team will ask

**What exactly gets recorded?** Committed evidence (`.shale/<session>.yaml`)
holds the agent's intent, the **paths** of files it touched and the operation
(write / edit / delete), the commands it ran and their exit codes, and the
model, tokens, cost, and timing. Nothing more.

**What does it deliberately *not* capture?**

- **File contents or diffs** — Shale records *that* `auth.go` changed, never
  *what* changed. The diff is already in the PR.
- **Gitignored files** — any touch whose path your repo ignores (`.env`,
  `*.pem`, `secrets/`, anything in `.gitignore`) is dropped at finalize. Secrets
  live in exactly those paths, so they never reach committed evidence.
- **Files outside the repo** — a path resolving outside the repo root is dropped.
- **Raw prompt text** — see below.

**What about secrets in commands?** Agent-authored text — intent, notes, and
the commands themselves — is run through a secret-redaction pass before it is
written. It catches vendor token shapes (AWS, GitHub, OpenAI, Anthropic, Slack,
Stripe, and more) plus the command-line forms agents actually use: env-prefix
assignments (`API_KEY=… ./run`), secret flags (`--token=…`, `--password …`),
and bearer headers. The command stays on the card — knowing the agent ran
`go test` is the point — only the secret *value* is masked.

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

**What permissions does it grant agents?** None by default. With your
explicit consent at `init` (an interactive `[y/N]`, or a flag in scripts),
it allowlists exactly three commands for Claude Code — `shale intent`,
`shale done`, `shale note` — in the committed `.claude/settings.json`.
Never `shale *`: uninstalling, re-initializing, and anything shipped later
still prompt. The grant is reviewable in the PR that adds it and
`shale uninstall --repo` removes precisely those entries.

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

**What if we try it and walk away?** `shale uninstall` removes everything on
your machine; `shale uninstall --repo` also removes the committed files
(commit the removal). It only deletes what Shale wrote — your instruction
files, your hook entries, and your hook manager's files survive. And because
the committed hooks are self-guarding, `brew uninstall shale` alone makes
everything go silent for you. No account to close, nothing left running.

## Start here

- **[Getting started](https://github.com/provasign/shale/blob/main/docs/getting-started.md)** — the full walkthrough, including branch protection setup
- **[CI integrations](https://github.com/provasign/shale/blob/main/docs/ci-integrations.md)** — Jenkins, CircleCI, GitHub Enterprise Server, and the env contract
- **[Live demo PRs](https://github.com/provasign/shale-test-bed/pulls?q=is%3Apr)** — happy path, coverage gaps, and the no-evidence nudge, on real PRs
- **[Troubleshooting](https://github.com/provasign/shale/blob/main/docs/troubleshooting.md)** — when something looks off
- **[Product & architecture](https://github.com/provasign/shale/blob/main/docs/product.md)** — design decisions, capture tiers, security model

[Get Shale on GitHub →](https://github.com/provasign/shale){: .btn .btn-primary }

## Where it fits

Shale and [Prism]({{ '/prism/' | relative_url }}) are the two core projects:
Prism provides change intelligence before an edit; Shale makes the resulting
work reviewable after it. [Mason]({{ '/mason/' | relative_url }}) is the
incubating reference agent that integrates both.

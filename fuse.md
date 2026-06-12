---
title: Fuse
layout: default
nav_order: 4
description: "A semantic git merge driver — symbol-aware three-way merge, AI conflict handoff, and drift evidence for agent teams."
permalink: /fuse/
---

# Fuse — merges that understand your code

Git merges text. When two branches touch the same lines, git gives up and
writes conflict markers — even when the changes are perfectly compatible: one
branch renamed a function, the other added a call site; one added an import,
the other reordered the list; two agents edited different methods of the same
class.

**What Fuse does:** it registers as a git merge driver and performs the
three-way merge at the *symbol* level, using the
[Grove]({{ '/grove/' | relative_url }}) code graph. Compatible changes merge
cleanly. Genuinely conflicting changes escalate — first to a structural
resolution, and only then to a conflict handoff an AI agent (or a human) can
resolve with full context.

```sh
brew install provasign/shale/fuse
cd your-repo
fuse init
```

After that, plain `git merge` and `git rebase` go through Fuse. No new
commands to learn, no workflow change.

---

## One command to set up: `fuse init`

`fuse init` is the complete per-repo setup:

1. **Merge driver** — sets `merge.fuse.*` in the repo's git config and adds
   the supported file patterns (`*.go`, `*.ts`, `*.py`, `*.java`, `*.rs`,
   and more — 14 types) to `.gitattributes`. Commit `.gitattributes` so the
   whole team gets semantic merges.
2. **MCP registration** — registers the `fuse` MCP server with every AI
   coding tool it detects: Claude Code (`.mcp.json`), Cursor, Windsurf,
   VS Code, Zed, and Codex CLI. Existing configs are merged, never
   overwritten.
3. **Agent steering** — writes a short "how to use the fuse_* tools" section
   into the instruction file of each agent format: `CLAUDE.md`,
   `.cursorrules`, `.windsurfrules`, `AGENTS.md`, `GEMINI.md`,
   `.github/copilot-instructions.md`, Cline, Devin, and Kiro.

Re-running `fuse init` is safe: it refreshes a stale steering section in
place, never duplicates `.gitattributes` lines, and leaves an
already-correct `.mcp.json` untouched.

```sh
fuse init [dir]           # full setup in the given repo (default: .)
fuse init --global        # MCP config at user level (~/.claude.json, ~/.cursor/…)
fuse init --skip-driver   # agent integration only, no merge driver
fuse install              # merge driver only (for CI or scripts)
fuse uninstall            # remove the merge driver registration
```

---

## How a merge escalates

Fuse never silently guesses. Each level only engages when the previous one
cannot prove the merge is safe:

| Level | What happens |
|---|---|
| **1 · Line merge** | Changes don't overlap — standard three-way text merge. |
| **2 · Symbol merge** | Overlapping lines, but different symbols: each function/class is merged independently. Handles renames (rename on one side, edits on the other), nested containers (two agents editing different methods of one class), and true set-semantics for imports. |
| **3 · Structural check** | The merged result is re-parsed. If any input had syntax errors, Fuse falls back to git's line-level result rather than trusting structure it can't verify. |
| **4 · Handoff** | A real semantic conflict: conflict markers are written, and a context-rich handoff prompt lands in `.git/fuse/` — the symbol, both sides' intent, blast radius from Grove, and the tests that pin the behavior. |

Every decision is recorded in an audit log (`fuse status` shows recent
merges), and each merge records **drift evidence** — which symbols were
added, removed, changed, or renamed — in `.git/fuse/drift.json`.
[Prism]({{ '/prism/' | relative_url }}) surfaces that drift to other agents
mid-session (`prism_drift`), so an agent whose context predates the merge
learns the ground shifted *before* it edits from stale memory.

---

## MCP tools

`fuse mcp` exposes four deliberately terse tools over stdio JSON-RPC —
results are summary-first (verdict + counts) because they land in an agent's
context window:

| Tool | Purpose |
|---|---|
| `fuse_merge_check` | Dry-run your committed HEAD against a ref: "will my work merge cleanly?" — verdict, per-file conflicts, breaking changes. ~40 tokens when clean. |
| `fuse_preview` | Three-way merge of in-memory content; returns merged text + whether conflicts remain. Nothing written. |
| `fuse_resolve` | Work a conflict handoff: fetch the prompt, validate a proposed resolution (no markers, parses cleanly), optionally apply it. |
| `fuse_impact` | Blast radius via the Grove graph — capped at 50 refs plus the true count. |

`fuse init` registers this automatically; to wire it manually, point your
agent at `fuse mcp [dir]`.

---

## Score it against your own history

Don't take the merge quality on faith — replay your repository's actual
merge history and see how many conflicts Fuse would have resolved:

```sh
fuse bench . --limit 200
```

For each historical merge commit, Fuse re-runs the three-way merge of the
parents and compares its output to what was actually committed.

---

## Troubleshooting

**`git merge` still produces ordinary conflicts.**
The driver only fires for paths listed in `.gitattributes`. Check both
halves of the registration:

```sh
git config merge.fuse.driver        # → fuse merge %O %A %B %P
git check-attr merge -- path/to/file.go   # → merge: fuse
```

If `check-attr` says `unspecified`, `.gitattributes` is missing the pattern
(or isn't committed on the branch being merged). Note that `git config` is
per-clone: every clone runs `fuse init` or `fuse install` once;
`.gitattributes` travels with the repo, the config does not.

**`fuse: command not found` during a merge — but `fuse version` works in
your shell.**
Git runs merge drivers through a non-interactive shell with a possibly
shorter `PATH`. Either install fuse somewhere global (`brew` handles this)
or set the driver to an absolute path:
`git config merge.fuse.driver "/opt/homebrew/bin/fuse merge %O %A %B %P"`.

**An old version keeps running.**
`which fuse` — a stale copy in `~/bin` shadows a newer Homebrew install.
Remove the old binary or make it a symlink to the brewed one.

**`fuse init` says "not a git repository".**
The merge driver registers into a repo's `.git/config`. Run it from inside
the repo, or pass the path: `fuse init path/to/repo`. Use `--skip-driver`
if you only want the agent integration.

**The fuse_* MCP tools don't show up in my agent.**
MCP servers load at session start — restart the agent session after
`fuse init`. In Claude Code, check that `.mcp.json` has the `fuse` entry
and approve the server when prompted.

**Merges feel slow on a huge repo.**
The first merge builds the Grove index (tens of seconds on very large
repos); after that, delta indexing makes it cheap. Native analyzers default
to a 5 s timeout — on very large repos set `GROVE_NATIVE_TIMEOUT=60s`.
Skips degrade gracefully; they never block the merge.

**A merge produced conflict markers — isn't Fuse supposed to fix that?**
When both sides change the *same symbol* in incompatible ways, no tool can
merge it honestly. Fuse's job at that point is the handoff: look in
`.git/fuse/` for the prompt, or let an agent run `fuse_resolve` /
`fuse resolve <file> --agent "claude -p" --apply`.

**Undo everything.**
`fuse uninstall` removes the git config; delete the `merge=fuse` lines from
`.gitattributes`. Merges immediately revert to git's standard behavior —
Fuse never changes how your history is stored.

---

## Installation

```sh
# Homebrew (macOS / Linux) — one tap for the family
brew install provasign/shale/fuse

# Script install (macOS / Linux)
curl -fsSL https://raw.githubusercontent.com/provasign/fuse/main/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/provasign/fuse/main/install.ps1 | iex

# Pin a version
VERSION=v0.8.0 curl -fsSL https://raw.githubusercontent.com/provasign/fuse/main/install.sh | bash
```

Then: `cd your-repo && fuse init`. There is also a GitHub Action example in
the repository for running Fuse-backed merges in CI.

---

## CLI reference

```sh
fuse init [dir] [--global] [--skip-driver]  # full setup: driver + MCP + steering
fuse install                     # merge driver only
fuse uninstall                   # remove driver registration
fuse merge <base> <ours> <theirs> [path]    # manual three-way merge (git calls this)
fuse preview <base> <ours> <theirs>         # print merged result, write nothing
fuse resolve <conflict-file> [--agent <cmd>] [--apply]   # AI-resolve a conflict
fuse check <file>                # breaking changes vs HEAD
fuse impact <file-or-symbol>     # blast radius via Grove
fuse deps <file>                 # dependency edges via Grove
fuse bench [repo] [--limit N]    # replay merge history, score accuracy
fuse status                      # recent merge decisions + drift
fuse config                      # resolved configuration
fuse mcp [dir]                   # stdio MCP server
```

---

## Where it fits

Fuse is the merge layer of the toolchain.
[Grove]({{ '/grove/' | relative_url }}) provides the code graph it merges
with; [Prism]({{ '/prism/' | relative_url }}) delivers the drift evidence
Fuse records to other agents mid-session;
[Shale]({{ '/shale/' | relative_url }}) puts the evidence of agent work on
the pull request.

[Get Fuse on GitHub →](https://github.com/provasign/fuse){: .btn .btn-primary }

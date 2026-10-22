---
title: Benchmarks
layout: default
nav_order: 6
description: "Prism v0.87.39 vs native Claude Code on change work and bug fixes, plus Grove engine accuracy."
permalink: /benchmarks/
---

# Prism benchmarks

Prism v0.87.39 (Grove v0.63.25, Astkit v0.16.10), measured 2026-10-21. Prism 1.0.0 is v0.87.39 plus a CLI help-text change, so these results apply to it. Earlier benchmark results are archived.

## Setup

Claude Code 2.1.302 with Claude Sonnet 5.5, run headless (`claude -p`). Each task ran twice: once with Claude Code's own tools (native), once with Prism set up through `prism init --interface cli`, where the agent runs the `prism` command in Bash and no MCP server is registered. Same task, same checkout, same tests in both arms.

Runs were generated with prompt caching off, then every request was repriced at Sonnet 5.5's 5-minute-cache prices (input $2, cache write $2.50, cache read $0.10, output $10 per million tokens). **Startup** is the first request of a session (system prompt, tools, project instructions). **Task cost** is everything after it. Tool calls are the actions the agent takes (each grep, read, edit, test run or `prism` command). Requests are model API calls.

A task is solved when its hidden tests pass (bug fixes), or when every affected site is changed and the project's tests pass (change work).

## Change work: 32 tasks

Seeded renames and signature changes in Python (12), Java (7), TypeScript (8) and Go (5). 24 rename an interface or base-class method that shares its name with unrelated methods, 4 rename a property or option, and 4 change a function's signature.

| | Native | Prism v0.87.39 | Prism / native |
|---|---:|---:|---:|
| Solved | 31 / 32 | **32 / 32** | |
| Task cost per task | $0.0646 | $0.0492 | **0.76×** |
| Tool calls per task | 6.8 | 4.4 | **0.65×** |
| Model requests per task (after startup) | 5.7 | 4.2 | **0.74×** |
| Startup per session | $0.0607 | $0.0626 | 1.03× |

By kind and language (Prism / native):

| Slice | Tasks | Solved native / Prism | Task cost | Tool calls |
|---|---:|---|---:|---:|
| Method rename (shared name) | 24 | 23 / 24 | 0.72× | 0.62× |
| Signature change | 4 | 4 / 4 | 0.85× | 0.60× |
| Property/option rename | 4 | 4 / 4 | 0.92× | 0.83× |
| Java | 7 | 7 / 7 | 0.74× | 0.58× |
| TypeScript | 8 | 7 / 8 | 0.74× | 0.66× |
| Go | 5 | 5 / 5 | 0.78× | 0.64× |
| Python | 12 | 12 / 12 | 0.81× | 0.69× |

Slices with 4-5 tasks show direction, not a precise figure.

The Prism arm comes from the v0.87.38-vs-v0.87.39 A/B run. The native arm comes from the same day's native-vs-v0.87.38 run on the same tasks and setup. v0.87.38 alone measured 31 / 32 solved, 0.84× task cost and 0.76× tool calls against native.

## Bug fixes: 40 GitHub issues

Real issues filed after the model's training cutoff, from Go, Java, TypeScript and Python projects (gin, chi, echo, urfave/cli, gson, jackson-databind, jackson-dataformat-xml, dubbo, hono, zod, urllib3, pydantic). Measured on Prism v0.87.37 (2026-10-20). v0.87.38 and v0.87.39 changed change-impact delivery and correctness, not the bug-fix path, and were not re-run on this set.

| | Native | Prism v0.87.37 | Prism / native |
|---|---:|---:|---:|
| Solved | 23 / 40 | 25 / 40 | |
| Task cost per task | $0.0520 | $0.0477 | **0.92×** |
| Tool calls per task | 6.85 | 5.85 | **0.85×** |
| Model requests per task (after startup) | 5.38 | 4.92 | 0.92× |
| Startup per session | $0.0609 | $0.0626 | 1.03× |

The solve difference (25 vs 23) is within run-to-run noise. Read it as the same result. 22 of the 40 are small one-file fixes (Prism 0.87× task cost, 0.88× tool calls). The other slices are too small to quote.

## Over a working session

Startup is paid once per session and task cost once per task. Projected saving of Prism vs native for a session of N tasks of one kind:

| Tasks in session | Change work | Bug fixes |
|---:|---:|---:|
| 1 | 11% | 2% |
| 10 | 21% | 7% |
| 20 | 22% | 8% |
| 40 | 23% | 8% |

The projection does not model context growth within a long session. It does not count Prism's one-time indexing, which costs time, not tokens.

## Limits

- One model (Sonnet 5.5), one agent (Claude Code), one run per cell. Opus was not measured against native.
- The change set has 4 signature-change and 4 property-rename tasks. Their rows are directional.
- Two losses were adjudicated, not dropped. Prism's werkzeug `HTTPException.get_headers` miss in the v0.87.38 run was a macOS `sed` `\b` substitution that changed nothing; Prism's change-impact had listed the right sites. Native missed hono `Router.match`.
- Claude Code's auto mode with Opus 5.5 adds a reminder to work through Bash with grep/cat. Under it, Prism still handled 80% (CLI) / 59% (MCP) of code searches. Savings under that reminder were not measured against native.

## Engine accuracy (Grove v0.63.25)

Call-edge precision and recall against each language's compiler or runtime ground truth on pinned repositories. CI-gated (`grove/eval/baseline.json`).

| Language | Corpus | Ground truth | Precision | Recall |
|---|---|---|---:|---:|
| Go | gin / cobra | SSA + VTA | 0.979 / 0.995 | 0.997 / 1.000 |
| Java | commons-lang / commons-io | javac + javap | 1.000 / 1.000 | 1.000 / 1.000 |
| C# | Newtonsoft.Json | Roslyn | 0.971 | 0.977 |
| TypeScript | socket.io / p-queue | TypeScript compiler API | 0.937 / 0.959 | 0.992 / 1.000 |
| JavaScript | express | TypeScript checker (checkJs) | 0.885 | 1.000 |
| Rust | ripgrep / fd | rust-analyzer SCIP | 0.965 / 0.952 | 0.906 / 0.913 |
| C | jansson / cJSON | clang | 1.000 / 0.998 | 0.998 / 0.999 |
| Swift | SwiftyJSON / Files | SourceKit | 1.000 / 1.000 | 1.000 / 1.000 |
| Kotlin | turtle | kotlinc + javap | 1.000 | 1.000 |
| Objective-C | json-framework / CocoaLumberjack | clang | 1.000 / 0.975 | 1.000 / 0.957 |
| Python | flask | pytest trace (dynamic) | 0.896 | 0.787 |
| PHP | PHP-Parser / league/csv | Xdebug trace (dynamic) | 0.922 / 0.947 | 0.683 / 0.837 |

COBOL and JCL are supported with a regression-tested graph. Their accuracy is not yet independently scored.

## Sources

- [Fact sheet: Prism v0.87.39 benchmark](https://github.com/provasign/prism/blob/main/docs/benchmarks/prism-v0.87.39-2026-10-21.md)
- [Raw records, transcripts and tallies](https://github.com/provasign/research/tree/main/harness/results) (`change32-cli-vs-native-2026-10-21`, `change32-v08739cand-2026-10-21`, `v0837-vs-native41-2026-10-20`)

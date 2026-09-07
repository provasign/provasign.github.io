---
title: Benchmarks
layout: default
nav_order: 6
description: "Current Prism accuracy and efficiency results, with repeated trials, methods, and limitations."
permalink: /benchmarks/
---

# Prism benchmarks

Prism is evaluated on whether a coding agent identifies every site affected by a code change. Accuracy is scored against committed ground truth; efficiency is reported beside it. The harness, tasks, oracles, run records, and transcripts are public in [provasign/research](https://github.com/provasign/research).

## Latest paired nine-task sample

These are fresh Sonnet runs on isolated repository snapshots. Native cells used ordinary search/read tools. Prism cells used the current Prism workflow.

| Task | Native R/P | Native cost | Prism R/P | Prism cost | Cost ratio |
|---|---:|---:|---:|---:|---:|
| Jackson `JsonNode.get` | 0.625 / 1.000 | $0.77 | **1.000 / 1.000** | **$0.27** | 0.35× |
| Jackson `SettableBeanProperty.set` | 0.591 / 0.867 | $0.16 | **1.000 / 1.000** | **$0.06** | 0.38× |
| TypeORM driver `escape` | 0.405 / 0.517 | $0.11 | **1.000 / 0.974** | **$0.07** | 0.65× |
| Django `quote_name` | 1.000 / 0.230 | $0.44 | **1.000 / 0.865** | **$0.08** | 0.19× |
| Jackson `writeTypePrefix` | 0.868 / 0.868 | $0.12 | **1.000 / 1.000** | **$0.08** | 0.64× |
| Guava forwarding `delegate` | 0.171 / 0.982 | $0.51 | **0.984 / 0.950** | **$0.23** | 0.46× |
| Jackson `serialize` | 0.574 / 0.639 | $0.64 | **1.000 / 0.864** | **$0.20** | 0.31× |
| Grafana `CheckHealth` | 1.000 / 0.922 | $0.23 | **1.000 / 0.983** | **$0.16** | 0.70× |
| Grafana `QueryData` | 0.914 / 0.901 | $0.25 | **1.000 / 0.959** | **$0.13** | 0.51× |
| **Aggregate** | **0.683 / 0.770 mean** | **$3.23** | **0.998 / 0.955 mean** | **$1.28** | **0.40×** |

Prism had higher recall in eight tasks, tied at full recall in one, and cost less in every task. Aggregate cost was 60% lower.

Each cell is one run. Agent behavior is variable, so this table is a release-gate snapshot. It shows broad current behavior; it does not establish a confidence interval.

## Repeated evidence

Three paired Jackson `JsonNode.get` trials used distinct sessions and snapshots:

| Workflow | Mean recall | Mean precision | Mean request tokens | Mean turns | Mean cost |
|---|---:|---:|---:|---:|---:|
| Native search/read | 0.625 | 1.000 | 656k | 30.0 | $0.404 |
| Prism | **1.000** | **1.000** | **215k** | **8.3** | **$0.205** |

For Grafana's external Go interfaces, three fresh Prism trials per task all reached full recall:

| Task | Oracle sites | Recall | Precision | Mean turns | Mean cost |
|---|---:|---:|---:|---:|---:|
| `QueryData` | 70 | 1.000 in all 3 | 0.933–0.959 | 4.0 | $0.172 |
| `CheckHealth` | 59 | 1.000 in all 3 | 0.983 | 5.0 | $0.229 |

The deterministic engine operation also scores 1.0 recall on both tasks. `QueryData` is structurally difficult because its interface is declared in the Grafana plugin SDK while dozens of unrelated local types satisfy it implicitly.

## What changed after the regression

Early `QueryData` candidates guessed concrete type names one at a time and missed implementations. The product fixes were general:

- resolve local Go methods that satisfy a compatible external interface method
- return exhaustive search overflow as a complete compact inventory of exact paths and enclosing symbols
- reserve detailed signatures and call expressions for ambiguous or heuristic impact edges
- steer agents from a small closure to exhaustive search instead of repeated name guessing

No repository or task names are embedded in Prism or Grove. Expected answers and thresholds live in the research harness.

## Oracle correction

The original Grafana `QueryData` oracle contained 51 sites. A source audit found that it excluded valid middleware implementations, another external-interface implementation, a production fake, and direct handler callers. The corrected oracle contains 70 sites. This explains why precision remained low across several engine changes: the measurement contract was incomplete.

The correction is part of the result. Ground truth is software and must be audited when a metric behaves implausibly.

## Session isolation

Freshness checks record the repository snapshot, model invocation ID, session ID, and transcript path for each cell. The repeated study used six distinct sessions and snapshots. Provider prompt caching reused static input prefixes where available; it did not share prior answers or conversation state.

## How to read the claims

- Recall and precision are the primary correctness measures.
- Cost claims are meaningful only beside comparable accuracy.
- Deterministic engine scores establish the graph's ceiling; agent scores include routing and response-assembly behavior.
- One-run cells show current breadth. Repeated trials show variance and expected behavior.
- Static analysis can be limited by reflection, runtime registration, generated code, or missing language toolchains. Completeness labels report those boundaries.

## Reproduce

```sh
git clone https://github.com/provasign/research
cd research/harness
python3 -m unittest discover -s tests
python3 impact_oracle.py tasks/grafana-querydata-impact.json
```

The [research results](https://github.com/provasign/research/blob/main/RESULTS.md) link to the current protocols and raw records. Historical and invalid experiments remain available with their validity findings.

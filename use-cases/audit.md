---
title: Audit
layout: default
parent: Use Cases
nav_order: 2
description: "How Provasign makes AI-generated changes auditable after the fact, with replayable cryptographic evidence."
permalink: /use-cases/audit/
nav_exclude: true
search_exclude: true
---

# Audit

Provasign makes AI-generated changes auditable *after the fact*, not just reviewable at the pull-request stage. The key audit question is not "did it merge?" — it's **"what exactly was asked, what ran, and what passed?"**

## The audit triple

Every Provasign-admitted commit carries three things:

1. **The prompt** — the user's verbatim request, committed as a YAML intent in `.provasign/intents/`, linked by an `Intent-ID:` trailer and tamper-checked by `Intent-Hash:`.
2. **The proof** — an Ed25519-signed certificate over the exact changeset, effective config hash, toolchain versions, policy results, and findings — including the **ICR hash** (a cryptographic commitment to exactly which symbols changed and what their blast radius was).
3. **The replay** — `provasign cert replay <id>` re-runs the gates and tells you whether the result still holds.

## The ICR hash — what the certificate actually certifies

The certificate's `ICR-Hash` is not a hash of the diff. It is a hash of the **semantic graph** of what changed: the specific symbols touched, every symbol one hop away in the code graph (the blast radius), and the tests Grove identified as covering them. Two changes that produce an identical diff can have different ICR hashes — because one might touch a function called by forty other things while the other touches a dead-end utility.

This means an auditor can do more than confirm "CI was green." They can:

- **Verify scope matches stated intent.** The intent says *"fix timing attack in validatePassword."* The ICR lists `validatePassword`, `Login`, `RequireAuth`, `PostLogin`. If a billing module had appeared, that's a flag worth investigating.
- **Confirm the certificate wasn't altered.** Recompute the hash from the symbol list and check it matches the `ICR-Hash` in the commit trailer. Editing the certificate to hide a symbol breaks the hash.
- **Confirm test coverage was meaningful.** The ICR names the specific tests Grove identified as covering the changed symbols — not "tests passed" but *which tests, and why they count*.
- **Detect scope creep across a sprint.** Compare ICR symbol lists across 10 commits. A commit described as "UI tweak" whose ICR includes `internal/auth/crypto.go::generateToken` warrants a question.

[Full worked example with commit trailers and JSON →]({{ '/architecture/#grove-in-action--the-icr' | relative_url }})

## Replay verdicts

| Verdict | Meaning for an auditor |
|---|---|
| `byte_reproducible` | The recorded gates still produce the same result under the same config |
| `tool_drift` | Same config, but an analyzer's verdict changed since admission |
| `config_drift` | The policy configuration has changed since the certificate was issued |
| `unrecoverable` | The recorded changeset can't be reconstructed from current state |

## Why it matters

CI logs roll off. Agent sessions vanish. "Refactor auth, LGTM, CI green" tells a future auditor nothing. Provasign preserves the chain so the evidence can be reconstructed months later — and exported as JSON-LD (`provasign cert show --jsonld`) for ingestion into an audit system.

This maps to SOC 2 CC4.1/CC4.2 (control monitoring) and produces the traceability record the EU AI Act expects for high-risk activities (active August 2026).

> **Laptop vs server mode.** In laptop mode the certificate store (`.provasign/engine.db`) and signing key are local and gitignored, so a fresh clone carries the committed intents and commit trailers but **not** the certificates or key — replay and signature verification therefore run only on the originating machine. A **portable audit trail that a third party can verify independently requires Provasign server (team) mode** (shared certificate store + KMS-backed signer), which is on the roadmap. See [Deployment modes]({{ '/architecture/#deployment-modes' | relative_url }}).

## Related

- [Security]({{ '/use-cases/security/' | relative_url }}) · [Traceability]({{ '/use-cases/traceability/' | relative_url }})
- [How It Works]({{ '/how-it-works/' | relative_url }})

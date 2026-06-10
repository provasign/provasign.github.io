---
title: Grove
layout: default
nav_order: 4
description: "Persistent code graph and indexing engine for direct graph use or embedded tools."
permalink: /grove/
---

# Grove

Grove is the graph engine.

Use Grove directly when you want the code graph itself: indexing, symbols,
impact, tests, semantic queries, or an embedded Go API for another product. Use
Prism when you want Grove-backed context delivery for agents. Use Shale when
you want agent PR evidence.

## Typical Use

```sh
grove index .
grove symbols AuthService
grove impact internal/auth/service.go::AuthService.Login
grove tests internal/auth/service.go::AuthService.Login
```

Grove is also available as a Go library at
`github.com/provasign/grove/pkg/grove`.

## Repository

[Read the Grove README on GitHub ->](https://github.com/provasign/grove#readme){: .btn .btn-primary }

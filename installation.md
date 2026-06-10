---
title: Installation
layout: default
nav_order: 7
description: "How to install Provasign on macOS, Linux, and Windows — from GitHub Releases binaries or from source."
permalink: /installation/
nav_exclude: true
search_exclude: true
---

# Installation

Provasign ships four single-file binaries: `grove`, `prism`, `fuse`, and `provasign`. Pick the installation method that fits your environment.

## One-Command Install (Fastest)

Each product has its own install script. Install the ones you need — Grove first,
since Prism, Fuse, and Provasign all embed it as a library.

**macOS / Linux:**

```bash
# Full suite
curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/provasign/fuse/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash

# Just one product — e.g. Provasign only:
curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash

# Pin a version:
VERSION=v0.4.0 curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash

# Install Provasign and initialize the current project in one step:
PROJECT="$PWD" curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/provasign/grove/main/install.ps1 | iex
irm https://raw.githubusercontent.com/provasign/prism/main/install.ps1 | iex
irm https://raw.githubusercontent.com/provasign/fuse/main/install.ps1 | iex
irm https://raw.githubusercontent.com/provasign/provasign/main/install.ps1 | iex
```

Each script installs to `~/bin` by default. Set `INSTALL_DIR=/usr/local/bin` to override.

After install, open a new terminal and restart your AI coding tool so it picks up
the MCP servers. Verify with `claude mcp list` (prism/provasign should show ✓ Connected).

## Agent Setup Prompt

Prefer a guided, conversational install (the agent asks which products, where to
install, VS Code extension mode)? Point your agent at the setup prompt:

[Open Agent Setup Guide]({{ '/setup/' | relative_url }}){: .btn .btn-primary .mr-2 }
[Agent Setup Prompt File](https://provasign.dev/assets/AGENT_SETUP_PROMPT.md){: .btn }

```bash
claude "Follow the setup instructions at https://provasign.dev/assets/AGENT_SETUP_PROMPT.md"
```

Prefer manual installation? Use the options below.

| Method | Best for | Speed |
|--------|---------|-------|
| [One-command installer](#one-command-install-fastest) | Most users, CI, quick setup | 30 seconds |
| [Pre-built binaries](#pre-built-binaries-from-github-releases) | Production use, CI, locked-down environments | 30 seconds |
| [Build from source](#build-from-source) | Developers, contributors, custom builds | 5 minutes |
| [Homebrew](#homebrew-macos--linux) | macOS / Linux users with Homebrew | 1 minute (planned) |

**Required:** Git 2.x. Everything else (Go toolchain, build dependencies) is only needed for source builds.

---

## Pre-built Binaries (from GitHub Releases)

Each product is released from its own GitHub repository. Binaries are built on
GitHub Actions for every release tag.

| Product | Releases |
|---------|---------|
| Grove | [github.com/provasign/grove/releases](https://github.com/provasign/grove/releases) |
| Prism | [github.com/provasign/prism/releases](https://github.com/provasign/prism/releases) |
| Fuse | [github.com/provasign/fuse/releases](https://github.com/provasign/fuse/releases) |
| Provasign | [github.com/provasign/provasign/releases](https://github.com/provasign/provasign/releases) |

### Supported platforms

| OS | Architecture | Binary suffix |
|----|-------------|---------------|
| Linux | amd64 (Intel/AMD x86_64) | `-linux-amd64` |
| Linux | arm64 (Graviton, Ampere, Raspberry Pi 4+) | `-linux-arm64` |
| macOS | amd64 (Intel Macs) | `-darwin-amd64` |
| macOS | arm64 (Apple Silicon M1/M2/M3/M4) | `-darwin-arm64` |
| Windows | amd64 | `-windows-amd64.exe` |

### macOS (Apple Silicon)

```bash
VERSION=v0.4.0   # check each repo's releases page for the latest

for product in grove prism fuse provasign; do
  curl -L "https://github.com/provasign/${product}/releases/download/${VERSION}/${product}-${VERSION}-darwin-arm64" \
    -o "${product}"
  chmod +x "${product}"
  xattr -d com.apple.quarantine "${product}" 2>/dev/null || true
  sudo mv "${product}" /usr/local/bin/
done

grove version && prism version && fuse version && provasign version
```

If macOS Gatekeeper blocks a binary on first run:

```bash
xattr -d com.apple.quarantine /usr/local/bin/grove
# repeat for prism, fuse, provasign
```

We're working on Apple Developer signing — until then, the quarantine-removal step is required.

### macOS (Intel)

Same as above but replace `darwin-arm64` with `darwin-amd64`.

### Linux (amd64)

```bash
VERSION=v0.4.0

for product in grove prism fuse provasign; do
  curl -L "https://github.com/provasign/${product}/releases/download/${VERSION}/${product}-${VERSION}-linux-amd64" \
    -o "${product}"
  chmod +x "${product}"
  sudo mv "${product}" /usr/local/bin/
done
```

### Linux (arm64 — Raspberry Pi, AWS Graviton, Ampere Altra)

Same as above but replace `linux-amd64` with `linux-arm64`.

### Windows

Each product has its own release page. Download the `.exe` for each product you want:

- [Grove releases](https://github.com/provasign/grove/releases/latest)
- [Prism releases](https://github.com/provasign/prism/releases/latest)
- [Fuse releases](https://github.com/provasign/fuse/releases/latest)
- [Provasign releases](https://github.com/provasign/provasign/releases/latest)

Move each `.exe` to a folder on your `PATH` (e.g. `C:\Users\<you>\bin\`) and rename to remove the version suffix:

```powershell
$VERSION = "v0.4.0"
foreach ($product in @("grove","prism","fuse","provasign")) {
  $src = "$product-$VERSION-windows-amd64.exe"
  Rename-Item $src "$product.exe"
}
```

Verify in a new PowerShell window: `grove version; prism version; fuse version; provasign version`

### Verifying downloads

When a release includes a `checksums.txt`, verify integrity before running:

```bash
PRODUCT=grove
VERSION=v0.4.0
curl -L "https://github.com/provasign/${PRODUCT}/releases/download/${VERSION}/checksums.txt" -o checksums.txt
sha256sum -c checksums.txt --ignore-missing
```

If any line says `FAILED`, **do not run the binary** — re-download or open an issue.
Not all releases include a `checksums.txt` yet; the install scripts always display
the SHA256 of whatever they download so you can verify manually.

### Pinning a version

Production deployments should pin to a specific tag rather than `latest`:

```bash
# Pin in CI / install scripts
VERSION=v0.4.0
```

Don't pin to `main` — that's our development branch.

---

## Build from Source

Build from source if:
- You're contributing to Provasign
- You need a build for an unsupported platform
- Your security policy requires building from source
- You want to test the unreleased main branch

### Prerequisites

| Tool | Version | Why |
|------|---------|-----|
| Go | 1.22+ (1.26+ recommended) | Compiler |
| Git | 2.x | Source checkout |
| `gcc` / `clang` / MSVC | any recent version | CGO compilation (tree-sitter requires C) |
| `make` | GNU make or BSD make | Build orchestration |

#### macOS prerequisites

```bash
# Install Xcode Command Line Tools (provides clang + git + make)
xcode-select --install

# Install Go
brew install go
```

#### Linux (Debian / Ubuntu) prerequisites

```bash
sudo apt update
sudo apt install -y golang-1.26 build-essential git make
# Or grab Go directly from https://go.dev/doc/install if your distro's package is older
```

#### Linux (Fedora / RHEL) prerequisites

```bash
sudo dnf install -y golang gcc make git
```

#### Windows prerequisites

1. Install Go from [go.dev/dl](https://go.dev/dl/) — pick the latest Windows installer
2. Install [Git for Windows](https://git-scm.com/download/win) — provides `git` and a bash shell
3. Install a C compiler: [MinGW-w64](https://www.mingw-w64.org/) or [TDM-GCC](https://jmeubank.github.io/tdm-gcc/) — required for CGO

### Build steps

Each product is in its own repo. Grove must be built first.

```bash
# Clone and build each repo (Grove first)
for product in grove prism fuse provasign; do
  git clone https://github.com/provasign/${product}
  cd ${product} && make install && cd ..
done
```

`make install` compiles and copies to `$GOPATH/bin` (default `~/go/bin`). Make sure that directory is on your `PATH`:

```bash
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

### Building a specific version

```bash
for product in grove prism fuse provasign; do
  cd ${product}
  git checkout v0.4.0
  make install
  cd ..
done
```

### Running tests after build

```bash
cd grove && make test && cd ..
cd prism && make test && cd ..
cd fuse  && make test && cd ..
cd provasign && make test && cd ..
```

---

## Homebrew (macOS & Linux)

**Status:** planned — not yet available.

When ready, you'll be able to:

```bash
brew tap provasign/provasign
brew install provasign       # installs all four
brew install grove             # or one at a time
brew install prism
brew install fuse
brew install provasign
```

[Track progress on this issue.](https://github.com/provasign/provasign/issues)

---

## After Installation

### 1. Initialize Prism in your project

```bash
cd /your/project
prism init    # auto-detects Claude Code / Copilot / Cursor / Codex CLI / Windsurf / Zed
              # writes MCP config + agent steering instructions
prism index   # initial code-graph index
```

Then restart your coding tool to pick up the MCP server.

### 2. Add symbol-aware merge (optional)

```bash
fuse install                           # writes ~/.gitconfig merge driver entry

# Per-repo, add to .gitattributes:
echo "*.go merge=fuse"  >> .gitattributes
echo "*.ts merge=fuse"  >> .gitattributes
echo "*.py merge=fuse"  >> .gitattributes
```

### 3. Add certified delivery (optional)

```bash
provasign init --stack=go-microservice    # scaffolds .provasign/, generates Ed25519 key
                                      # writes agent instructions + MCP config
                                      # for every detected coding tool
provasign hook install                    # git pre-push backstop

# Pre-download analyzer dependencies now so provasign_check never silently skips
# tools on first use. For deterministic behavior, install the full stack.
provasign tools install --with-sonar      # gitleaks, govulncheck, golangci-lint + JRE + SonarLint jars
# Semgrep/Ruff are Python packages — install separately:
# pipx install semgrep
# pipx install ruff

# Verify there are no missing analyzer dependencies.
provasign doctor

git add .provasign/ && git commit -m "Add Provasign configuration"
```

Pick the stack matching your project: `go-microservice` | `node-api` | `python-service` | `java-spring`. List all with `provasign init --list-stacks`.

---

## Verify Everything Works

After installation, run a smoke test:

```bash
# Health check — all four binaries on PATH
which grove prism fuse provasign

# Version sanity
grove version
prism version
fuse version
provasign version

# Start Grove and verify HTTP API
# Grove is now an embedded library — Prism, Fuse, and Provasign open the on-disk
# index in-process. The CLI is still available for one-shot queries:
grove index .
grove symbols main

# Use Prism to query (in a project that has been indexed)
cd /your/project
prism index
prism query "where is authentication handled?"
```

---

## Uninstall

### One-command uninstall (macOS / Linux)

```bash
cd /path/to/provasign
./scripts/uninstall-provasign.sh /path/to/your/project
```

What it removes automatically:

- Provasign-managed hooks and MCP registrations (via `provasign local uninstall` when provasign is available)
- Provasign downloaded tool cache (via `provasign tools uninstall` when provasign is available)
- Grove/Prism/Fuse/Provasign binaries from common install paths
- Source-build binaries from `$GOPATH/bin`
- Per-user runtime/cache dirs (`~/.provasign`, `~/.grove`, `~/.prism`, `~/.fuse`, `~/.cache/prism`)
- Per-project runtime state (`.grove`, `.git/fuse`, workspace MCP config files)

Windows uninstall automation is planned; until then use the PowerShell removal commands.

---

## Common Installation Issues

### "command not found" after install

Your `PATH` doesn't include the install directory.

- **Source build:** add `$GOPATH/bin` (typically `~/go/bin`) to your `PATH`
- **Binary install (macOS/Linux):** `/usr/local/bin/` should already be on `PATH` — check with `echo $PATH`
- **Binary install (Windows):** add `C:\Users\<you>\bin\` to your `PATH` via System Properties → Environment Variables

### macOS: "cannot be opened because the developer cannot be verified"

```bash
xattr -d com.apple.quarantine /usr/local/bin/grove
xattr -d com.apple.quarantine /usr/local/bin/prism
xattr -d com.apple.quarantine /usr/local/bin/fuse
xattr -d com.apple.quarantine /usr/local/bin/provasign
```

This is the macOS Gatekeeper challenge on unsigned binaries. We're working on Apple Developer signing.

### `make install` fails with CGO error

Tree-sitter (used by Grove and Fuse) requires a C compiler.

- **macOS:** `xcode-select --install`
- **Linux:** `sudo apt install build-essential` or `sudo dnf groupinstall "Development Tools"`
- **Windows:** install MinGW-w64 or TDM-GCC

### Port conflicts

In the embedded model Grove no longer opens TCP ports. The only
port you may need to manage is Provasign's API server (default 9000). Configure it
via `provasign init` or the `RELAY_PORT` environment variable.

### Behind a corporate proxy

Set the standard proxy env vars before running:

```bash
export HTTP_PROXY=http://proxy.corp:8080
export HTTPS_PROXY=http://proxy.corp:8080
export NO_PROXY=localhost,127.0.0.1
```

Provasign doesn't make external HTTP calls during normal operation, so proxies only matter for `go install` / `git clone` during source builds.

---

## Where to Go Next

- **[Get up and running fast]({{ '/why/#what-we-want-from-you' | relative_url }})** — the 5-minute path with Prism
- **[Documentation home]({{ '/' | relative_url }})** — full doc map
- **[Troubleshooting]({{ '/troubleshooting/' | relative_url }})** — common operational issues
- **[Compare to alternatives]({{ '/comparisons/' | relative_url }})** — Prism vs Copilot, Fuse vs git merge, Provasign vs CI

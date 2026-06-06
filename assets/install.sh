#!/usr/bin/env bash
#
# ⚠️  This script is deprecated.
#
# Install scripts have moved to each product's own repository:
#
#   Grove:      curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash
#   Prism:      curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
#   Fuse:       curl -fsSL https://raw.githubusercontent.com/provasign/fuse/main/install.sh | bash
#   Provasign:  curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash
#
# Windows (PowerShell) — same pattern with install.ps1:
#   irm https://raw.githubusercontent.com/provasign/provasign/main/install.ps1 | iex
#
set -euo pipefail

cat >&2 <<'EOF'

  ⚠️  provasign.dev/assets/install.sh is deprecated.

  Install scripts now live in each product's own repo. Use:

    curl -fsSL https://raw.githubusercontent.com/provasign/grove/main/install.sh | bash
    curl -fsSL https://raw.githubusercontent.com/provasign/prism/main/install.sh | bash
    curl -fsSL https://raw.githubusercontent.com/provasign/fuse/main/install.sh | bash
    curl -fsSL https://raw.githubusercontent.com/provasign/provasign/main/install.sh | bash

  For guided agent-driven setup, use the per-product prompt:
    Prism:      https://raw.githubusercontent.com/provasign/prism/main/AGENT_SETUP_PROMPT.md
    Fuse:       https://raw.githubusercontent.com/provasign/fuse/main/AGENT_SETUP_PROMPT.md
    Provasign:  https://raw.githubusercontent.com/provasign/provasign/main/AGENT_SETUP_PROMPT.md

EOF
exit 1

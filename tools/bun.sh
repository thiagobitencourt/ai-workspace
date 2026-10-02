#!/usr/bin/env bash
# check: bun
set -euo pipefail
# Bun runtime (needed by the vercel plugin). Official installer: https://bun.com/docs/installation
[[ -x "$HOME/.bun/bin/bun" ]] && exit 0
curl -fsSL https://bun.com/install | bash

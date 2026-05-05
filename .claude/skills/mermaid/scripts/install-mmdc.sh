#!/usr/bin/env bash
# install-mmdc.sh — install @mermaid-js/mermaid-cli locally and verify it runs
# Installs node/npm if missing, then npm installs mmdc, then runs mmdc -h to confirm.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}"

# ── 1. Ensure node is available ───────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "install-mmdc: node not found — attempting to install via nvm or package manager..." >&2

  if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    [[ -s "$HOME/.nvm/nvm.sh" ]] && source "$HOME/.nvm/nvm.sh"
    nvm install --lts
    nvm use --lts
  elif command -v brew &>/dev/null; then
    brew install node
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y nodejs npm
  elif command -v apk &>/dev/null; then
    apk add --no-cache nodejs npm
  else
    echo "install-mmdc: cannot install node — no known package manager found" >&2
    echo "  Please install Node.js (https://nodejs.org) and re-run this script." >&2
    exit 1
  fi
fi

node_version="$(node --version)"
npm_version="$(npm --version)"
echo "install-mmdc: node ${node_version}, npm ${npm_version}" >&2

# ── 2. Install @mermaid-js/mermaid-cli ───────────────────────────────────────
cd "$INSTALL_DIR"

if [[ ! -f package.json ]]; then
  npm init -y --quiet >/dev/null
fi

echo "install-mmdc: installing @mermaid-js/mermaid-cli ..." >&2
npm install @mermaid-js/mermaid-cli

MMDC="$INSTALL_DIR/node_modules/.bin/mmdc"

if [[ ! -x "$MMDC" ]]; then
  echo "install-mmdc: mmdc binary not found at $MMDC after install" >&2
  exit 1
fi

# ── 3. Smoke-test ─────────────────────────────────────────────────────────────
echo "install-mmdc: running mmdc -h ..." >&2
"$MMDC" -h
echo "install-mmdc: success — mmdc is ready at $MMDC" >&2

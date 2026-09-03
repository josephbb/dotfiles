#!/usr/bin/env bash
# Apply a host flake attribute, then run safe post-switch cleanup.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Override with DOTFILES_HOST, or DOTFILES_FLAKE for a full flake ref.
HOST="${DOTFILES_HOST:-macbook}"
FLAKE="${DOTFILES_FLAKE:-$ROOT#$HOST}"
OLLAMA_SETUP="$ROOT/scripts/ollama-setup.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [darwin-rebuild args...]

Host: $HOST (set DOTFILES_HOST to target another hosts/<name> config)

Runs:
  1. sudo darwin-rebuild switch --flake $FLAKE …
  2. brew cleanup -s
  3. AWS CLI v2 (official install.sh → ~/.local) — install or update
  4. sudo nix-collect-garbage -d
  5. nix store optimise
  6. ollama prune (if Ollama is installed) — retired tags + partial blobs only
     (does NOT pull models; use ollama-setup for that)

Extra args are forwarded to darwin-rebuild (e.g. --show-trace).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "==> darwin-rebuild switch --flake $FLAKE $*"
sudo darwin-rebuild switch --flake "$FLAKE" "$@"

echo
echo "==> brew cleanup -s"
if command -v brew >/dev/null 2>&1; then
  brew cleanup -s || true
else
  echo "brew not found; skipping"
fi

echo
echo "==> AWS CLI v2 (official installer)"
# User-local install: ~/.local/share/aws-cli + symlinks in ~/.local/bin
curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash

echo
echo "==> nix-collect-garbage -d"
sudo nix-collect-garbage -d

echo
echo "==> nix store optimise"
nix store optimise || true

echo
if [[ -x "$OLLAMA_SETUP" ]] && command -v ollama >/dev/null 2>&1; then
  echo "==> ollama prune (retired models + partial downloads)"
  "$OLLAMA_SETUP" prune || true
else
  echo "==> ollama prune skipped (Ollama not installed or setup script missing)"
fi

echo
echo "Rebuild + cleanup done."
echo "If shell aliases changed: exec zsh"
echo "To pull/refresh Continue models: ollama-setup"

#!/usr/bin/env bash
# Apply the macbook flake, then run safe post-switch cleanup.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLAKE="${DOTFILES_FLAKE:-$ROOT#macbook}"
OLLAMA_SETUP="$ROOT/scripts/ollama-setup.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [darwin-rebuild args...]

Runs:
  1. sudo darwin-rebuild switch --flake $FLAKE …
  2. brew cleanup -s
  3. sudo nix-collect-garbage -d
  4. nix store optimise
  5. ollama prune (if Ollama is installed) — retired tags + partial blobs only
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

#!/usr/bin/env bash
# Interactively enable/disable optional features in hosts/<host>/features.toml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${DOTFILES_HOST:-macbook}"
FEATURES="$ROOT/hosts/$HOST/features.toml"

KNOWN_FEATURES=(ollama research)

usage() {
  cat <<EOF
Usage: $(basename "$0") <enable|disable|status> [feature]

Host: $HOST (set DOTFILES_HOST for another machine)
Features file: $FEATURES

Features:
  ollama     Local LLM runtime + VS Code Continue (large models; needs rebuild)
  research   TeX Live / R / Quarto / RStudio (heavy; disable on weaker machines)

Examples:
  $(basename "$0") status
  $(basename "$0") enable ollama
  $(basename "$0") disable research
EOF
}

ensure_section() {
  local feature="$1"
  if ! grep -q "^\[${feature}\]" "$FEATURES" 2>/dev/null; then
    printf '\n[%s]\nenabled = false\n' "$feature" >>"$FEATURES"
  fi
}

get_enabled() {
  local feature="$1"
  awk -v feat="$feature" '
    $0 == "[" feat "]" { in_section=1; next }
    /^\[/ { in_section=0 }
    in_section && $1 == "enabled" {
      gsub(/ /, "", $3)
      print $3
      exit
    }
  ' "$FEATURES"
}

set_enabled() {
  local feature="$1"
  local value="$2"
  ensure_section "$feature"
  # Rewrite enabled= inside the matching section only.
  awk -v feat="$feature" -v val="$value" '
    $0 == "[" feat "]" { in_section=1; print; next }
    /^\[/ { in_section=0 }
    in_section && $1 == "enabled" {
      print "enabled = " val
      next
    }
    { print }
  ' "$FEATURES" >"${FEATURES}.tmp"
  mv "${FEATURES}.tmp" "$FEATURES"
}

ask_confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

if [[ ! -f "$FEATURES" ]]; then
  echo "No features file for host '$HOST' at $FEATURES" >&2
  echo "Create hosts/$HOST/ (copy from macbook) and register it in flake.nix." >&2
  exit 1
fi

cmd="${1:-}"
feature="${2:-ollama}"

case "$cmd" in
  status)
    echo "Feature flags ($FEATURES):"
    for f in "${KNOWN_FEATURES[@]}"; do
      echo "  $f.enabled = $(get_enabled "$f")"
    done
    ;;
  enable)
    current="$(get_enabled "$feature" || true)"
    if [[ "$current" == "true" ]]; then
      echo "$feature is already enabled."
      exit 0
    fi
    case "$feature" in
      ollama)
        cat <<'EOF'
Enable Ollama?
  - Installs Homebrew cask: ollama-app
  - Adds VS Code Continue extension + ~/.continue/config.yaml
  - Models (pull after rebuild with `ollama-pull-defaults`):
      qwen3-coder-next
      llama3.3:70b-instruct-q4_K_M
      qwen3-coder:30b-a3b-q8_0
      qwen2.5-coder:7b-base-q4_K_M
  - Tuned for M5 Max / 128GB unified memory.
EOF
        ;;
      research)
        cat <<'EOF'
Enable research stack?
  - home-manager: just, watchexec, sqlite, duckdb, quarto, pandoc, R, radian, texliveFull
  - Homebrew cask: rstudio (+ Dock pin on hosts that declare it)
  - texliveFull is a large download
EOF
        ;;
      *)
        echo "Unknown feature: $feature" >&2
        usage
        exit 1
        ;;
    esac
    if ! ask_confirm "Write enabled = true for [$feature]?"; then
      echo "Aborted."
      exit 0
    fi
    set_enabled "$feature" true
    echo "Enabled [$feature]. Run: rebuild"
    ;;
  disable)
    case "$feature" in
      ollama | research) ;;
      *)
        echo "Unknown feature: $feature" >&2
        usage
        exit 1
        ;;
    esac
    if ! ask_confirm "Disable [$feature]?"; then
      echo "Aborted."
      exit 0
    fi
    set_enabled "$feature" false
    echo "Disabled [$feature]. Run: rebuild"
    ;;
  -h | --help | "")
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac

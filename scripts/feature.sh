#!/usr/bin/env bash
# Interactively enable/disable optional features in hosts/macbook/features.toml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEATURES="$ROOT/hosts/macbook/features.toml"

usage() {
  cat <<EOF
Usage: $(basename "$0") <enable|disable|status> [feature]

Features:
  ollama   Local LLM runtime + VS Code Continue (large models; needs rebuild)

Examples:
  $(basename "$0") status
  $(basename "$0") enable ollama
  $(basename "$0") disable ollama
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

cmd="${1:-}"
feature="${2:-ollama}"

case "$cmd" in
  status)
    echo "Feature flags ($FEATURES):"
    echo "  ollama.enabled = $(get_enabled ollama)"
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
      *)
        echo "Unknown feature: $feature" >&2
        usage
        exit 1
        ;;
    esac
    if ! ask_confirm "Write enabled = true for [$feature]?"; then
      echo "Aborted."
      exit 1
    fi
    set_enabled "$feature" true
    echo "Enabled [$feature]. Run: rebuild"
    ;;
  disable)
    if ! ask_confirm "Disable [$feature]?"; then
      echo "Aborted."
      exit 1
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

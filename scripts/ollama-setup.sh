#!/usr/bin/env bash
# Post-rebuild Ollama helper: start app if needed, pull Continue defaults,
# remove retired models and interrupted partial download blobs.
set -euo pipefail

API="http://localhost:11434"
OLLAMA_HOME="${OLLAMA_HOME:-$HOME/.ollama}"
BLOBS_DIR="$OLLAMA_HOME/models/blobs"

# Current Continue defaults (M5 Max / 128GB).
MODELS=(
  "qwen3-coder-next"
  "llama3.3:70b-instruct-q4_K_M"
  "qwen3-coder:30b-a3b-q8_0"
  "qwen2.5-coder:7b-base-q4_K_M"
)

# Previous defaults / redundant tags — remove if present.
RETIRED=(
  "llama3.1:70b-instruct-q4_K_M"
  "llama3.1:70b"
  "qwen2.5-coder:32b-instruct-q8_0"
  "qwen2.5-coder:32b"
  # short tag duplicates the explicit q8 alt below
  "qwen3-coder:30b"
  "qwen3-coder:latest"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [status|pull|prune|setup]

  setup   Start Ollama if needed, clean partials, pull defaults, prune retired (default)
  pull    Pull default models only (API must already be up)
  prune   Remove retired models + interrupted *-partial-* blobs
  status  Show binary, API health, partial bloat, and installed models
EOF
}

have_ollama() {
  command -v ollama >/dev/null 2>&1
}

api_up() {
  curl -fsS "$API/api/tags" >/dev/null 2>&1
}

installed_names() {
  # First column of `ollama list`, skip header.
  ollama list 2>/dev/null | awk 'NR>1 {print $1}'
}

has_model() {
  local want="$1"
  local name
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ "$name" == "$want" || "$name" == "$want:latest" ]]; then
      return 0
    fi
  done < <(installed_names)
  return 1
}

partial_files() {
  if [[ -d "$BLOBS_DIR" ]]; then
    # Interrupted pulls create both `*-partial` and `*-partial-N` files (often sparse).
    find "$BLOBS_DIR" -type f \( -name '*-partial' -o -name '*-partial-*' \) 2>/dev/null || true
  fi
}

partial_bytes() {
  local total=0
  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total + $(stat -f%z "$f" 2>/dev/null || echo 0)))
  done < <(partial_files)
  echo "$total"
}

human_bytes() {
  local bytes="$1"
  if ((bytes >= 1073741824)); then
    awk -v b="$bytes" 'BEGIN { printf "%.1fG", b/1073741824 }'
  elif ((bytes >= 1048576)); then
    awk -v b="$bytes" 'BEGIN { printf "%.1fM", b/1048576 }'
  elif ((bytes >= 1024)); then
    awk -v b="$bytes" 'BEGIN { printf "%.1fK", b/1024 }'
  else
    echo "${bytes}B"
  fi
}

# Interrupted `ollama pull` leaves *-partial-* blobs that eat disk until cleaned.
clean_partials() {
  if [[ ! -d "$BLOBS_DIR" ]]; then
    echo "No blobs dir at $BLOBS_DIR — nothing to clean."
    return 0
  fi

  local count=0
  local bytes
  bytes="$(partial_bytes)"
  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    rm -f "$f"
    count=$((count + 1))
  done < <(partial_files)

  if [[ "$count" -eq 0 ]]; then
    echo "No interrupted partial downloads to remove."
  else
    echo "Removed $count partial download blob(s) ($(human_bytes "$bytes"))."
  fi
}

start_ollama() {
  if api_up; then
    echo "Ollama API already up ($API)."
    return 0
  fi

  if [[ -d /Applications/Ollama.app ]]; then
    echo "Starting Ollama.app…"
    open -a Ollama
  elif have_ollama; then
    echo "Starting ollama serve in background…"
    nohup ollama serve >/tmp/ollama-serve.log 2>&1 &
  else
    echo "Ollama not installed. Enable [ollama] in hosts/macbook/features.toml and run: rebuild" >&2
    exit 1
  fi

  echo -n "Waiting for API"
  for _ in $(seq 1 60); do
    if api_up; then
      echo " — ready."
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo
  echo "Timed out waiting for $API" >&2
  exit 1
}

pull_defaults() {
  if ! have_ollama; then
    echo "ollama not on PATH" >&2
    exit 1
  fi
  if ! api_up; then
    echo "API down. Run: $(basename "$0") setup" >&2
    exit 1
  fi

  for model in "${MODELS[@]}"; do
    echo "→ ollama pull $model"
    ollama pull "$model"
  done
}

prune_retired() {
  if ! have_ollama; then
    echo "ollama not on PATH" >&2
    exit 1
  fi
  if ! api_up; then
    echo "API down. Run: $(basename "$0") setup" >&2
    exit 1
  fi

  local removed=0
  for model in "${RETIRED[@]}"; do
    # Never prune something that is still a current default.
    local still_wanted=0
    for keep in "${MODELS[@]}"; do
      if [[ "$model" == "$keep" ]]; then
        still_wanted=1
        break
      fi
    done
    if [[ "$still_wanted" -eq 1 ]]; then
      continue
    fi

    if has_model "$model"; then
      echo "→ ollama rm $model"
      ollama rm "$model"
      removed=$((removed + 1))
    fi
  done

  if [[ "$removed" -eq 0 ]]; then
    echo "No retired models to remove."
  else
    echo "Removed $removed retired model(s)."
  fi
}

show_status() {
  if have_ollama; then
    echo "Ollama binary: $(command -v ollama)"
  else
    echo "Ollama binary: not found"
  fi

  if api_up; then
    echo "API: up ($API)"
  else
    echo "API: down"
  fi

  if [[ -d /Applications/Ollama.app ]]; then
    echo "App: /Applications/Ollama.app"
  else
    echo "App: not found"
  fi

  local pcount=0
  local pbytes
  pbytes="$(partial_bytes)"
  while IFS= read -r _; do
    [[ -z "$_" ]] && continue
    pcount=$((pcount + 1))
  done < <(partial_files)
  if [[ "$pcount" -gt 0 ]]; then
    echo "Partials: $pcount interrupted blob(s) ($(human_bytes "$pbytes")) — run prune/setup to clear"
  else
    echo "Partials: none"
  fi

  echo "Wanted:"
  for model in "${MODELS[@]}"; do
    if have_ollama && has_model "$model"; then
      echo "  [have] $model"
    else
      echo "  [need] $model"
    fi
  done

  if have_ollama; then
    echo "Installed:"
    ollama list 2>/dev/null || true
  fi
}

cmd="${1:-setup}"
case "$cmd" in
  setup)
    start_ollama
    # Clear interrupted downloads before fresh pulls so they don't leave dead weight.
    clean_partials
    pull_defaults
    prune_retired
    echo "Done. Installed models:"
    ollama list
    ;;
  pull)
    pull_defaults
    ;;
  prune)
    prune_retired
    clean_partials
    ;;
  status)
    show_status
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac

#!/usr/bin/env bash
# Pull the OpenCode pack used by the sandboxed `opencode` function.
set -euo pipefail

if ! command -v nono >/dev/null 2>&1; then
  echo "nono is not on PATH. Run rebuild first." >&2
  exit 1
fi

exec nono pull nolabs-ai/opencode

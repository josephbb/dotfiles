#!/usr/bin/env bash
# Register this project's .venv as a Jupyter kernel for VS Code / Cursor.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KERNEL_NAME="${KERNEL_NAME:-$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')}"
KERNEL_DISPLAY="${KERNEL_DISPLAY:-Python ($KERNEL_NAME)}"

if ! command -v nix >/dev/null 2>&1; then
  echo "error: nix is required" >&2
  exit 1
fi

echo "→ nix develop: uv sync + install kernel \"$KERNEL_DISPLAY\"…"
nix develop --command bash -c "
  set -euo pipefail
  uv sync
  uv run python -m ipykernel install \
    --user \
    --name='$KERNEL_NAME' \
    --display-name='$KERNEL_DISPLAY'
"

echo ""
echo "Done. In VS Code: open analysis.ipynb → Select Kernel → Jupyter Kernel → $KERNEL_DISPLAY"

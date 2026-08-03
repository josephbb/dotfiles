#!/usr/bin/env bash
# Register this project's .venv as a Jupyter kernel for VS Code / Cursor.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KERNEL_NAME="${KERNEL_NAME:-$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')}"
KERNEL_DISPLAY="${KERNEL_DISPLAY:-Python ($KERNEL_NAME)}"
KERNEL_JSON="${HOME}/Library/Jupyter/kernels/${KERNEL_NAME}/kernel.json"

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

# Pin a clean env so notebooks don't inherit a polluted parent shell
# (DYLD_LIBRARY_PATH + nix OpenBLAS breaks Accelerate-linked NumPy on macOS).
# shellHook prints a banner; take only the store path line.
CMDSTAN_PATH="$(
  nix develop --command bash -c 'printf %s "$CMDSTAN"' 2>/dev/null \
    | tr ' \n' '\n' \
    | grep -E '^/nix/store/.+/opt/cmdstan$' \
    | tail -n1 \
    || true
)"
export KERNEL_JSON CMDSTAN_PATH
python3 - <<'PY'
import json
import os
from pathlib import Path

kernel = Path(os.environ["KERNEL_JSON"])
data = json.loads(kernel.read_text())
env = data.setdefault("env", {})
env["DYLD_LIBRARY_PATH"] = ""
env["DYLD_FALLBACK_LIBRARY_PATH"] = ""
env.pop("DYLD_INSERT_LIBRARIES", None)
cmdstan = os.environ.get("CMDSTAN_PATH", "").strip()
if cmdstan:
    env["CMDSTAN"] = cmdstan
else:
    env.pop("CMDSTAN", None)
kernel.write_text(json.dumps(data, indent=1) + "\n")
print(f"→ wrote clean env into {kernel}")
PY

echo ""
echo "Done. In VS Code: open analysis.ipynb → Select Kernel → Jupyter Kernel → $KERNEL_DISPLAY"
echo "If NumPy still fails: Kernel → Restart Kernel (or reload the window)."

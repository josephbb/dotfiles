# Python analysis template

Barebones **nix + uv** starter: data/output folders, `src/`, `analysis.ipynb`, and a VS Code kernel installer.

## Create a project

```bash
nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
cd ~/Projects/my-analysis
direnv allow          # or: nix develop
uv sync
./scripts/install_kernel.sh
```

## Layout

```text
analysis.ipynb
palettes.toml         # named plot color palettes
data/                 # inputs (gitignored contents)
output/               # figures, tables, traces (gitignored contents)
src/                  # your modules (includes palettes.py)
scripts/install_kernel.sh
flake.nix             # dev shell + native libs for SciPy/PyMC
pyproject.toml        # numpy, scipy, pandas, polars, pymc[nutpie], arviz, …
```

Load a palette in a notebook:

```python
from src.palettes import load_palette
p = load_palette("hinoki_forest")
# p.ember_clay, p.forest_shade, …
```

## Stack

numpy, scipy, pandas, polars, pymc (≥6) with nutpie, arviz, xarray, matplotlib — plus `ipykernel` for notebooks.

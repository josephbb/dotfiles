# Bayes analysis template

**nix + uv** starter for Bayesian workflows: PyMC, NumPyro, CmdStanPy, ArviZ, Bambi, and Kulprit — plus data/output folders, `src/`, `analysis.ipynb`, palettes, and a VS Code kernel installer.

## Create a project

```bash
nix flake new -t ~/dotfiles#bayes ~/Projects/my-model
cd ~/Projects/my-model
direnv allow          # or: nix develop
uv sync
./scripts/install_kernel.sh
```

(Former `#python` template — use `#bayes` now.)

## Layout

```text
analysis.ipynb
palettes.toml         # named plot color palettes
data/                 # inputs (gitignored contents)
output/               # figures, tables, traces (gitignored contents)
src/                  # your modules (includes palettes.py)
scripts/install_kernel.sh
flake.nix             # dev shell + native libs (SciPy / PyMC / CmdStan)
pyproject.toml
```

Load a palette in a notebook:

```python
from src.palettes import load_palette
p = load_palette("hinoki_forest")
# p.ember_clay, p.forest_shade, …
```

## Stack

| Role | Packages |
|---|---|
| Data / plots | numpy, scipy, pandas, polars, matplotlib, xarray |
| PPLs | **PyMC** (+ nutpie), **NumPyro** (+ JAX), **CmdStanPy** |
| Diagnostics / comparison | **ArviZ** |
| Formula models | **Bambi** (selected case studies) |
| Variable selection | **Kulprit** |
| Model graphs | **graphviz** (Python) + `dot` from the flake |
| Notebooks | ipykernel |

CmdStan comes from the flake (`CMDSTAN` is set in the shell). If you ever need a local install instead:

```bash
python -c 'import cmdstanpy; cmdstanpy.install_cmdstan()'
```

# Scratch template

Light **nix + uv** sandbox for a blog post, quick figure, or one-off notebook. No PyMC — use `#bayes` for that.

## Create a project

```bash
nix flake new -t ~/dotfiles#scratch ~/Projects/blog-note
cd ~/Projects/blog-note
direnv allow
uv sync
./scripts/install_kernel.sh
```

## Layout

```text
analysis.ipynb
data/
output/
src/
scripts/install_kernel.sh
flake.nix
pyproject.toml
```

## Stack

numpy, pandas, polars, matplotlib + ipykernel.

# Project templates

Flake starters for research projects. Create one with:

```bash
nix flake new -t ~/dotfiles#<name> ~/Projects/<dir>
```

`#scratch` is the **default** (`nix flake new -t ~/dotfiles ~/Projects/…`).

| Id | Path | When to use |
|---|---|---|
| [`scratch`](scratch/) | Light Python | Blog note, quick figure, one notebook |
| [`bayes`](bayes/) | PyMC / NumPyro / CmdStanPy + ArviZ / Bambi / Kulprit | Bayesian modeling |
| [`openalex`](openalex/) | Harvest → Parquet | OpenAlex datasets under `~/Datasets` |
| [`r`](r/) | renv + Quarto | Occasional R / tidyverse |

Former `#python` → use **`#bayes`**.

## After create

**Python** (`scratch`, `bayes`, `openalex`):

```bash
cd ~/Projects/<dir>
direnv allow          # .envrc → use flake
uv sync
./scripts/install_kernel.sh   # optional Jupyter / VS Code kernel
```

**R** (`r`):

```bash
cd ~/Projects/<dir>
direnv allow
# in R or RStudio:
renv::init()
install.packages(c("tidyverse", "here"))
renv::snapshot()
quarto preview analysis.qmd
```

RStudio is already on the machine (Homebrew cask). Large data stays in `~/Datasets`, not the repo.

## Shared conventions (Python)

- **nix + uv + direnv** — flake provides the shell; uv pins the package set
- **`.envrc`** — `use flake` (one `direnv allow` per project)
- **Bulk data gitignored** — prefer `~/Datasets/{scratch,raw,derived}` for anything large
- **Kernel script** — `scripts/install_kernel.sh` registers the uv env for notebooks

## OpenAlex data flow

Project repo = code + small config. Payloads live under `~/Datasets`:

| Stage | Path | Role |
|---|---|---|
| Cache | `~/Datasets/scratch/<slug>/openalex/` | Wipeable JSONL (default fetch target) |
| Raw (optional) | `~/Datasets/raw/<slug>/openalex/` | Provenance freeze (`fetch.py --promote`) |
| Derived | `~/Datasets/derived/<slug>/openalex/` | Parquet = analysis source of truth |

`[query.*]` in the project `config.toml` mirrors [LLMDiscourse](https://github.com/josephbb/LLMDiscourse) (years, journals, search mode/terms, …) so the template can grow into a fuller analysis repo. Details: [`openalex/README.md`](openalex/README.md).

Optional `catalog.duckdb` is a rebuildable SQL view over Parquet—not a server DB. Load creds with `openalex-load` before fetch.

## Registering templates

Ids are declared in the root [`../flake.nix`](../flake.nix) `templates` attrset. Adding a new starter: put a directory under `templates/`, then register `path` + `description` there.

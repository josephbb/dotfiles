# OpenAlex dataset template

Harvest OpenAlex into a **scratch JSONL cache**, optionally freeze to **raw**, compile to **Parquet** under `~/Datasets`, with optional **DuckDB** views.

## Create a project

```bash
nix flake new -t ~/dotfiles#openalex ~/Projects/oa-industry-ties
cd ~/Projects/oa-industry-ties
# edit config.toml → project_slug, filter, mailto
direnv allow
uv sync
./scripts/install_kernel.sh
```

## Credentials

```bash
openalex-load    # from dotfiles agenix secret
echo "$OPENALEX_API_KEY"
```

## Data flow

| Stage | Path | Role |
|---|---|---|
| Cache | `~/Datasets/scratch/<slug>/openalex/pages.jsonl` | Wipeable API cache |
| Raw (optional) | `~/Datasets/raw/<slug>/openalex/pages.jsonl` | Provenance freeze (`--promote`) |
| Derived | `~/Datasets/derived/<slug>/openalex/*.parquet` | Analysis tables |
| DuckDB (optional) | `…/catalog.duckdb` | SQL views over Parquet |

```bash
uv run python scripts/fetch.py              # → scratch
uv run python scripts/fetch.py --promote    # scratch + copy to raw
uv run python scripts/compile.py --duckdb   # → derived Parquet (+ duckdb)
```

## Layout

```text
config.toml
queries/
scripts/fetch.py
scripts/compile.py
scripts/install_kernel.sh
notebooks/explore.ipynb
src/paths.py
```

Repo holds code + config only — not the multi‑GB JSON.

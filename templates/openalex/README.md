# OpenAlex dataset template

Harvest OpenAlex into a **scratch JSONL cache**, optionally freeze to **raw**, compile to **Parquet** under `~/Datasets`, with optional **DuckDB** views.

Query config uses the same **`[query.*]`** shape as [LLMDiscourse](https://github.com/josephbb/LLMDiscourse) (`dataset_config.toml`), so this starter can grow into a fuller analysis repo without rewriting filters.

## Create a project

```bash
nix flake new -t ~/dotfiles#openalex ~/Projects/oa-industry-ties
cd ~/Projects/oa-industry-ties
# edit config.toml → project_slug, [query.*], mailto
direnv allow
uv sync
./scripts/install_kernel.sh
```

## Credentials

```bash
openalex-load    # from dotfiles agenix secret
echo "$OPENALEX_API_KEY"
```

## Query (`config.toml`)

Supported sections (built into OpenAlex `/works` params by `src/query.py`):

| Section | Effect |
|---|---|
| `[query.years]` | `publication_year` (`start` / optional `end`) |
| `[query.works]` | `type` (e.g. `article`) |
| `[query.journals]` | `primary_location.source.id` OR-list when `enabled` |
| `[query.citations]` | `cited_by_count` when `min >= 1` |
| `[query.abstract]` | `has_abstract:true` when `required` |
| `[query.domain]` | Social Sciences domain id `2` when `social_sciences` |
| `[query.search]` | `mode` + `terms` → `search.title_and_abstract[.exact]` etc. |
| `[query.sort]` | `sort` param |
| `[query.download]` | `per_page` |

Not in this template (stay in LLMDiscourse): disclosure lookbacks, institutions/funders, per-paper skip/prune, scrape.

```bash
uv run python -m unittest tests.test_query -v
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
config.toml              # [project] + [query.*]
queries/example.toml     # fuller query sketch to copy from
scripts/fetch.py
scripts/compile.py
src/query.py             # corpus_query / openalex_works_params
src/paths.py
notebooks/explore.ipynb
tests/test_query.py
```

Repo holds code + config only — not the multi‑GB JSON.

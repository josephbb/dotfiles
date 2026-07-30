#!/usr/bin/env python3
"""Compile OpenAlex JSONL cache → Parquet (+ optional DuckDB views).

Reads scratch pages.jsonl by default (or raw/ if --from-raw).
Writes under ~/Datasets/derived/<slug>/openalex/.

Usage:
  uv run python scripts/compile.py
  uv run python scripts/compile.py --from-raw
  uv run python scripts/compile.py --duckdb
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import polars as pl

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from paths import load_paths  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--from-raw",
        action="store_true",
        help="Compile from Datasets/raw instead of scratch cache",
    )
    parser.add_argument(
        "--duckdb",
        action="store_true",
        help="Also build catalog.duckdb with views over the Parquet files",
    )
    args = parser.parse_args()

    paths = load_paths()
    src = paths.raw_jsonl if args.from_raw else paths.scratch_jsonl
    if not src.is_file():
        raise SystemExit(
            f"missing JSONL: {src}\n  run: uv run python scripts/fetch.py"
        )

    paths.derived.mkdir(parents=True, exist_ok=True)
    print(f"reading {src}")

    works_rows: list[dict] = []
    authorship_rows: list[dict] = []
    concept_rows: list[dict] = []
    source_rows: list[dict] = []

    with src.open(encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            w = json.loads(line)
            wid = w.get("id")
            works_rows.append(
                {
                    "id": wid,
                    "doi": w.get("doi"),
                    "title": w.get("display_name") or w.get("title"),
                    "publication_year": w.get("publication_year"),
                    "cited_by_count": w.get("cited_by_count"),
                    "is_oa": (w.get("open_access") or {}).get("is_oa"),
                    "type": w.get("type"),
                    "language": w.get("language"),
                }
            )
            for a in w.get("authorships") or []:
                author = a.get("author") or {}
                authorship_rows.append(
                    {
                        "work_id": wid,
                        "author_id": author.get("id"),
                        "author_name": author.get("display_name"),
                        "author_position": a.get("author_position"),
                        "is_corresponding": a.get("is_corresponding"),
                    }
                )
            for c in w.get("concepts") or []:
                concept_rows.append(
                    {
                        "work_id": wid,
                        "concept_id": c.get("id"),
                        "concept_name": c.get("display_name"),
                        "score": c.get("score"),
                        "level": c.get("level"),
                    }
                )
            primary = w.get("primary_location") or {}
            source = primary.get("source") or {}
            if source.get("id"):
                source_rows.append(
                    {
                        "work_id": wid,
                        "source_id": source.get("id"),
                        "source_name": source.get("display_name"),
                        "issn_l": source.get("issn_l"),
                        "type": source.get("type"),
                    }
                )

    tables = {
        "works": pl.DataFrame(works_rows),
        "authorships": pl.DataFrame(authorship_rows),
        "concepts": pl.DataFrame(concept_rows),
        "sources": pl.DataFrame(source_rows),
    }
    for name, df in tables.items():
        dest = paths.derived / f"{name}.parquet"
        df.write_parquet(dest)
        print(f"  wrote {dest} ({df.height} rows)")

    if args.duckdb:
        build_duckdb(paths.derived)

    print("done")


def build_duckdb(derived: Path) -> None:
    import duckdb

    db_path = derived / "catalog.duckdb"
    if db_path.is_file():
        db_path.unlink()
    con = duckdb.connect(str(db_path))
    for name in ("works", "authorships", "concepts", "sources"):
        pq = derived / f"{name}.parquet"
        if pq.is_file():
            con.execute(
                f"CREATE VIEW {name} AS SELECT * FROM read_parquet('{pq}')"
            )
    con.close()
    print(f"  wrote {db_path}")


if __name__ == "__main__":
    main()

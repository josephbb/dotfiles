#!/usr/bin/env python3
"""Fetch OpenAlex works into ~/Datasets/scratch/<slug>/openalex/pages.jsonl (cache).

Builds the API query from config.toml [query.*] (same shape as LLMDiscourse).

Usage:
  openalex-load
  uv run python scripts/fetch.py
  uv run python scripts/fetch.py --force          # overwrite cache
  uv run python scripts/fetch.py --promote        # also copy cache → raw/
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path
from urllib.parse import urlencode

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from paths import load_config  # noqa: E402
from query import openalex_works_params  # noqa: E402

API = "https://api.openalex.org/works"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--promote",
        action="store_true",
        help="Copy finished scratch JSONL into Datasets/raw (optional provenance freeze)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing scratch cache",
    )
    args = parser.parse_args()

    cfg = load_config()
    cfg.scratch.mkdir(parents=True, exist_ok=True)
    out = cfg.scratch_jsonl

    if out.is_file() and not args.force:
        print(f"scratch cache exists: {out}")
        print("  pass --force to re-fetch")
        if args.promote:
            promote(cfg)
        return

    api_key = os.environ.get("OPENALEX_API_KEY", "").strip()
    if not api_key:
        print(
            "warning: OPENALEX_API_KEY unset — run `openalex-load` for higher limits",
            file=sys.stderr,
        )

    headers = {
        "User-Agent": f"openalex-template (mailto:{cfg.mailto})",
    }
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    base_params = openalex_works_params(cfg.query, per_page=cfg.per_page)
    print(f"filter={base_params['filter']!r}")
    for key, value in base_params.items():
        if key.startswith("search"):
            preview = value if len(value) < 120 else value[:117] + "…"
            print(f"{key}={preview!r}")
    print(f"sort={base_params.get('sort')!r}")
    print(f"writing → {out}")

    n = 0
    pages = 0
    cursor = "*"
    with out.open("w", encoding="utf-8") as fh, httpx.Client(
        headers=headers, timeout=60.0
    ) as client:
        while cursor:
            params = openalex_works_params(
                cfg.query, per_page=cfg.per_page, cursor=cursor
            )
            if api_key:
                params["api_key"] = api_key
            params["mailto"] = cfg.mailto
            url = f"{API}?{urlencode(params)}"
            res = client.get(url)
            res.raise_for_status()
            payload = res.json()
            results = payload.get("results") or []
            pages += 1
            for work in results:
                fh.write(json.dumps(work, ensure_ascii=False) + "\n")
                n += 1
            print(f"  page {pages}: {n} works so far")
            meta = payload.get("meta") or {}
            cursor = meta.get("next_cursor")
            if cfg.max_pages is not None and pages >= cfg.max_pages:
                print(f"  stopped at max_pages={cfg.max_pages}")
                break
            if not results:
                break
            time.sleep(0.1)

    print(f"done: {n} works → {out}")
    if args.promote:
        promote(cfg)


def promote(cfg) -> None:
    cfg.raw_dir.mkdir(parents=True, exist_ok=True)
    if not cfg.scratch_jsonl.is_file():
        raise SystemExit(f"no scratch cache to promote: {cfg.scratch_jsonl}")
    shutil.copy2(cfg.scratch_jsonl, cfg.raw_jsonl)
    print(f"promoted → {cfg.raw_jsonl}")


if __name__ == "__main__":
    main()

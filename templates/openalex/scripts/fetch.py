#!/usr/bin/env python3
"""Fetch OpenAlex works into ~/Datasets/scratch/<slug>/openalex/pages.jsonl (cache).

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
from urllib.parse import quote

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from paths import load_paths  # noqa: E402

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

    paths = load_paths()
    paths.scratch.mkdir(parents=True, exist_ok=True)
    out = paths.scratch_jsonl

    if out.is_file() and not args.force:
        print(f"scratch cache exists: {out}")
        print("  pass --force to re-fetch")
        if args.promote:
            promote(paths)
        return

    api_key = os.environ.get("OPENALEX_API_KEY", "").strip()
    if not api_key:
        print(
            "warning: OPENALEX_API_KEY unset — run `openalex-load` for higher limits",
            file=sys.stderr,
        )

    headers = {
        "User-Agent": f"openalex-template (mailto:{paths.mailto})",
    }
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    print(f"filter={paths.oa_filter!r}")
    print(f"writing → {out}")

    n = 0
    pages = 0
    cursor = "*"
    with out.open("w", encoding="utf-8") as fh, httpx.Client(
        headers=headers, timeout=60.0
    ) as client:
        while cursor:
            url = (
                f"{API}?filter={quote(paths.oa_filter, safe=':,')}"
                f"&per-page={paths.per_page}&cursor={quote(cursor, safe='*')}"
            )
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
            if paths.max_pages is not None and pages >= paths.max_pages:
                print(f"  stopped at max_pages={paths.max_pages}")
                break
            if not results:
                break
            time.sleep(0.1)

    print(f"done: {n} works → {out}")
    if args.promote:
        promote(paths)


def promote(paths) -> None:
    paths.raw.mkdir(parents=True, exist_ok=True)
    if not paths.scratch_jsonl.is_file():
        raise SystemExit(f"no scratch cache to promote: {paths.scratch_jsonl}")
    shutil.copy2(paths.scratch_jsonl, paths.raw_jsonl)
    print(f"promoted → {paths.raw_jsonl}")


if __name__ == "__main__":
    main()

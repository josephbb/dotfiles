#!/usr/bin/env python3
"""Build CV + enabled statement PDFs from config.toml."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    with (ROOT / "config.toml").open("rb") as f:
        cfg = tomllib.load(f)
    docs = cfg.get("documents") or {}
    jobs: list[tuple[str, Path]] = []
    cv = ROOT / "cv" / "cv.tex"
    if cv.is_file():
        jobs.append(("cv", cv))
    mapping = {
        "research_statement": ROOT / "statements" / "research-statement.tex",
        "teaching_statement": ROOT / "statements" / "teaching-statement.tex",
        "diversity_statement": ROOT / "statements" / "diversity-statement.tex",
        "mentoring_statement": ROOT / "statements" / "mentoring-statement.tex",
    }
    for key, path in mapping.items():
        if docs.get(key, False) and path.is_file():
            jobs.append((key, path))
    if not jobs:
        sys.exit("Nothing to build — sync a CV and enable documents in config.toml")
    for label, path in jobs:
        print(f"==> {label}: {path.relative_to(ROOT)}")
        subprocess.run(["latexmk", "-pdf", "-cd", str(path)], check=True)


if __name__ == "__main__":
    main()

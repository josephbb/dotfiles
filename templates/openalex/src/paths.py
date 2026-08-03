"""Resolve ~/Datasets paths and load project config.toml."""

from __future__ import annotations

import os
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from query import corpus_query


def project_root() -> Path:
    here = Path(__file__).resolve()
    for parent in here.parents:
        if (parent / "config.toml").is_file():
            return parent
    raise FileNotFoundError("config.toml not found")


def _expand(path: str) -> Path:
    return Path(os.path.expanduser(path)).resolve()


@dataclass(frozen=True)
class ProjectConfig:
    root: Path
    raw: dict[str, Any]
    slug: str
    scratch: Path
    raw_dir: Path
    derived: Path
    mailto: str
    query: dict[str, Any]
    per_page: int
    max_pages: int | None

    @property
    def scratch_jsonl(self) -> Path:
        return self.scratch / "pages.jsonl"

    @property
    def raw_jsonl(self) -> Path:
        return self.raw_dir / "pages.jsonl"


def load_config(config_path: Path | None = None) -> ProjectConfig:
    root = project_root()
    cfg_path = config_path or (root / "config.toml")
    with cfg_path.open("rb") as f:
        cfg = tomllib.load(f)

    if "query" not in cfg:
        raise ValueError(
            "config.toml needs a [query] section (see README). "
            "Raw openalex.filter strings are no longer used."
        )

    proj = cfg["project"]
    oa = cfg.get("openalex", {})
    datasets = _expand(proj.get("datasets_root", "~/Datasets"))
    slug = proj["project_slug"]
    download = cfg["query"].get("download", {})
    max_pages = oa.get("max_pages")

    return ProjectConfig(
        root=root,
        raw=cfg,
        slug=slug,
        scratch=datasets / "scratch" / slug / "openalex",
        raw_dir=datasets / "raw" / slug / "openalex",
        derived=datasets / "derived" / slug / "openalex",
        mailto=proj.get("mailto", "research@example.com"),
        query=corpus_query(cfg),
        per_page=int(download.get("per_page", oa.get("per_page", 200))),
        max_pages=int(max_pages) if max_pages is not None else None,
    )


# Back-compat alias used by older script imports
def load_paths(config_path: Path | None = None) -> ProjectConfig:
    return load_config(config_path)

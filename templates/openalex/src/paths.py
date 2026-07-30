"""Resolve ~/Datasets paths for this OpenAlex project."""

from __future__ import annotations

import os
import tomllib
from dataclasses import dataclass
from pathlib import Path


def project_root() -> Path:
    here = Path(__file__).resolve()
    for parent in here.parents:
        if (parent / "config.toml").is_file():
            return parent
    raise FileNotFoundError("config.toml not found")


def _expand(path: str) -> Path:
    return Path(os.path.expanduser(path)).resolve()


@dataclass(frozen=True)
class Paths:
    root: Path
    slug: str
    scratch: Path
    raw: Path
    derived: Path
    mailto: str
    oa_filter: str
    per_page: int
    max_pages: int | None

    @property
    def scratch_jsonl(self) -> Path:
        return self.scratch / "pages.jsonl"

    @property
    def raw_jsonl(self) -> Path:
        return self.raw / "pages.jsonl"


def load_paths(config_path: Path | None = None) -> Paths:
    root = project_root()
    cfg_path = config_path or (root / "config.toml")
    with cfg_path.open("rb") as f:
        cfg = tomllib.load(f)

    proj = cfg["project"]
    oa = cfg["openalex"]
    datasets = _expand(proj.get("datasets_root", "~/Datasets"))
    slug = proj["project_slug"]
    base = {
        "scratch": datasets / "scratch" / slug / "openalex",
        "raw": datasets / "raw" / slug / "openalex",
        "derived": datasets / "derived" / slug / "openalex",
    }
    max_pages = oa.get("max_pages")
    return Paths(
        root=root,
        slug=slug,
        scratch=base["scratch"],
        raw=base["raw"],
        derived=base["derived"],
        mailto=proj.get("mailto", "research@example.com"),
        oa_filter=oa["filter"],
        per_page=int(oa.get("per_page", 200)),
        max_pages=int(max_pages) if max_pages is not None else None,
    )

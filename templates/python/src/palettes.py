"""Load named plot palettes from the project's palettes.toml."""

from __future__ import annotations

import tomllib
from pathlib import Path
from types import SimpleNamespace

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_PALETTES_PATH = _PROJECT_ROOT / "palettes.toml"


def _load_all() -> dict[str, dict[str, str]]:
    with _PALETTES_PATH.open("rb") as f:
        return tomllib.load(f)


def list_palettes() -> list[str]:
    """Return available palette names."""
    return sorted(_load_all())


def load_palette(name: str) -> SimpleNamespace:
    """Return a palette as attributes, e.g. ``p.ember_clay``.

    Parameters
    ----------
    name :
            Key of a ``[palette]`` table in ``palettes.toml``.
    """
    palettes = _load_all()
    try:
        colors = palettes[name]
    except KeyError as exc:
        available = ", ".join(sorted(palettes)) or "(none)"
        raise KeyError(f"Unknown palette {name!r}. Available: {available}") from exc
    return SimpleNamespace(**colors)

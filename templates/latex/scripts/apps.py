#!/usr/bin/env python3
"""Track per-university applications: list, create, set status, ship, checklist."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore

ROOT = Path(__file__).resolve().parents[1]
APPS_PATH = ROOT / "applications.toml"
CONFIG_PATH = ROOT / "config.toml"
LETTER_TEMPLATE = ROOT / "letters" / "_template.tex"
STATUSES = ("planned", "in_progress", "done", "shipped", "interview", "closed")
STATUS_ORDER = {s: i for i, s in enumerate(STATUSES)}

# Canonical material ids used in requires[] / upload{}
MATERIAL_LABELS = {
    "cover_letter": "Cover letter",
    "cv": "CV",
    "research_statement": "Research statement",
    "teaching_statement": "Teaching statement",
    "diversity_statement": "Diversity / DEI statement",
    "mentoring_statement": "Mentoring statement",
    "references": "References / letters of rec",
    "writing_sample": "Writing sample",
    "teaching_evals": "Teaching evaluations",
    "transcripts": "Transcripts",
    "other": "Other",
}

KEY_ORDER = [
    "slug",
    "institution",
    "department",
    "position",
    "requisition",
    "status",
    "timing",
    "deadline",
    "review_begins",
    "timezone",
    "portal",
    "ad_url",
    "contact",
    "interfolio",
    "letter",
    "requires",
    "upload",
    "sources",
    "notes",
    "shipped_on",
    # legacy flat overrides (still supported)
    "research",
    "teaching",
    "diversity",
    "mentoring",
]

TIMINGS = (
    "deadline",  # hard due date in deadline=
    "rolling",  # reviewed as received; deadline optional
    "open_until_filled",
    "review_begins",  # use review_begins= date; deadline optional
    "unknown",
)


def load_toml(path: Path) -> dict:
    if not path.is_file():
        return {}
    with path.open("rb") as f:
        return tomllib.load(f)


def load_apps() -> dict:
    data = load_toml(APPS_PATH)
    data.setdefault("applications", [])
    return data


def load_config() -> dict:
    return load_toml(CONFIG_PATH)


def default_requires() -> list[str]:
    cfg = load_config()
    req = (cfg.get("defaults") or {}).get("requires")
    if isinstance(req, list) and req:
        return [str(x) for x in req]
    return [
        "cover_letter",
        "cv",
        "research_statement",
        "teaching_statement",
        "diversity_statement",
        "references",
    ]


def default_upload(slug: str, requires: list[str]) -> dict[str, str]:
    """Map material id → path we produce (or a note for external items)."""
    mapping = {
        "cover_letter": f"letters/{slug}.pdf",
        "cv": "cv/cv.pdf",
        "research_statement": "statements/research-statement.pdf",
        "teaching_statement": "statements/teaching-statement.pdf",
        "diversity_statement": "statements/diversity-statement.pdf",
        "mentoring_statement": "statements/mentoring-statement.pdf",
        "references": "(Interfolio / portal — not built here)",
        "writing_sample": "(add path)",
        "teaching_evals": "(add path)",
        "transcripts": "(add path)",
        "other": "(add path)",
    }
    return {k: mapping.get(k, "(add path)") for k in requires}


def _toml_str(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return str(value)
    if isinstance(value, list):
        inner = ", ".join(_toml_str(v) for v in value)
        return f"[ {inner} ]" if value else "[]"
    if isinstance(value, dict):
        if not value:
            return "{}"
        parts = [f"{k} = {_toml_str(v)}" for k, v in value.items()]
        return "{ " + ", ".join(parts) + " }"
    s = str(value)
    if "\n" in s:
        return '"""\n' + s.replace('"""', '\\"""') + '\n"""'
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def save_apps(data: dict) -> None:
    chunks = [
        "# Per-university / per-search tracker for this cycle.",
        "# Status: planned → in_progress → done → shipped (also: interview | closed)",
        "# Fields: where (portal/ad_url), when (timing/deadline optional), what (requires), files (upload)",
        "# Manage: just status | just app-new | just app-show | just app-status | just ship",
        "",
    ]
    for app in data.get("applications", []):
        chunks.append("[[applications]]")
        keys = [k for k in KEY_ORDER if k in app]
        keys.extend(k for k in app.keys() if k not in keys)
        for key in keys:
            val = app[key]
            if val is None:
                continue
            chunks.append(f"{key} = {_toml_str(val)}")
        chunks.append("")
    APPS_PATH.write_text("\n".join(chunks).rstrip() + "\n", encoding="utf-8")


def find_app(apps: list[dict], slug: str) -> dict:
    for app in apps:
        if app.get("slug") == slug:
            return app
    sys.exit(
        f"No application with slug {slug!r}. Known: "
        + (", ".join(a.get("slug", "?") for a in apps) or "(none)")
    )


def slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-") or "app"


def format_when(app: dict) -> str:
    """Human-readable timing; deadline is optional."""
    timing = (app.get("timing") or "").strip()
    deadline = (app.get("deadline") or "").strip()
    review = (app.get("review_begins") or "").strip()
    tz = (app.get("timezone") or "").strip()

    if not timing:
        if deadline:
            timing = "deadline"
        elif review:
            timing = "review_begins"
        else:
            timing = "unknown"

    if timing == "deadline":
        core = deadline or "(no date set)"
    elif timing == "rolling":
        core = f"rolling" + (f"; prefer by {deadline}" if deadline else "")
    elif timing == "open_until_filled":
        core = "open until filled" + (f"; posted goal {deadline}" if deadline else "")
    elif timing == "review_begins":
        core = f"review begins {review or '?'}" + (f"; apply by {deadline}" if deadline else "")
    else:
        core = deadline or "no deadline listed"

    return f"{core} {tz}".strip()


def sort_when_key(app: dict) -> str:
    """Sort key: dated apps first by deadline/review_begins, then undated."""
    return app.get("deadline") or app.get("review_begins") or "9999-99-99"


def resolve_upload_path(raw: str) -> Path | None:
    """Return a filesystem path for existence checks; None if external/note."""
    raw = (raw or "").strip()
    if not raw or raw.startswith("(") or raw.lower().startswith("http"):
        return None
    p = Path(raw)
    if not p.is_absolute():
        p = ROOT / p
    return p


def packet_rows(app: dict) -> list[tuple[str, str, str, str]]:
    """Rows: id, label, dest, status."""
    requires = app.get("requires") or default_requires()
    upload = dict(app.get("upload") or {})
    # Fill missing upload entries from defaults
    defaults = default_upload(app.get("slug") or "app", list(requires))
    rows = []
    for mid in requires:
        dest = upload.get(mid) or defaults.get(mid) or "(add path)"
        label = MATERIAL_LABELS.get(mid, mid)
        path = resolve_upload_path(dest)
        if path is None:
            st = "external"
        elif path.is_file():
            st = "ready"
        elif path.with_suffix(".tex").is_file() and path.suffix == ".pdf":
            st = "need_pdf"
        else:
            st = "missing"
        rows.append((mid, label, dest, st))
    return rows


def cmd_list(args: argparse.Namespace) -> None:
    data = load_apps()
    apps = list(data["applications"])
    if args.status:
        apps = [a for a in apps if a.get("status") == args.status]
    apps.sort(
        key=lambda a: (
            STATUS_ORDER.get(a.get("status", ""), 99),
            sort_when_key(a),
            a.get("slug") or "",
        )
    )
    if not apps:
        print("No applications." + (f" (filter status={args.status})" if args.status else ""))
        return
    print(f"{'STATUS':<12} {'SLUG':<16} {'WHEN':<28} INSTITUTION")
    print("-" * 78)
    for a in apps:
        when = format_when(a)
        if len(when) > 28:
            when = when[:25] + "…"
        print(
            f"{a.get('status', ''):<12} {a.get('slug', ''):<16} {when:<28} "
            f"{a.get('institution', '')} / {a.get('department', '')}"
        )
    counts: dict[str, int] = {}
    for a in data["applications"]:
        st = a.get("status") or "?"
        counts[st] = counts.get(st, 0) + 1
    print("-" * 78)
    print(
        "Totals: "
        + ", ".join(f"{k}={v}" for k, v in sorted(counts.items(), key=lambda kv: STATUS_ORDER.get(kv[0], 99)))
    )
    print("Detail: just app-show <slug>")


def cmd_new(args: argparse.Namespace) -> None:
    data = load_apps()
    slug = args.slug or slugify(args.institution)
    if any(a.get("slug") == slug for a in data["applications"]):
        sys.exit(f"slug {slug!r} already exists")
    letter = ROOT / "letters" / f"{slug}.tex"
    if letter.exists() and not args.force:
        sys.exit(f"{letter.relative_to(ROOT)} already exists (pass --force to reuse file)")
    if not letter.exists():
        if not LETTER_TEMPLATE.is_file():
            sys.exit(f"Missing letter template {LETTER_TEMPLATE}")
        letter.write_text(LETTER_TEMPLATE.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"Created {letter.relative_to(ROOT)}")

    requires = list(args.require) if args.require else default_requires()
    # allow comma-separated --require cover_letter,cv,...
    flat: list[str] = []
    for item in requires:
        flat.extend(x.strip() for x in item.split(",") if x.strip())
    requires = flat or default_requires()

    app = {
        "slug": slug,
        "institution": args.institution,
        "department": args.department or "",
        "position": args.position or "Assistant Professor",
        "requisition": args.requisition or "",
        "status": "planned",
        "timing": args.timing or ("deadline" if args.deadline else "unknown"),
        "deadline": args.deadline or "",
        "review_begins": args.review_begins or "",
        "timezone": args.timezone or "",
        "portal": args.portal or "",
        "ad_url": args.ad_url or "",
        "contact": args.contact or "",
        "interfolio": args.interfolio or "",
        "letter": str(letter.relative_to(ROOT)),
        "requires": requires,
        "upload": default_upload(slug, requires),
        "sources": {},
        "notes": args.notes or "",
        "shipped_on": "",
    }
    data["applications"].append(app)
    data["applications"] = [
        a
        for a in data["applications"]
        if not (a.get("slug") == "example" and "Replace or delete" in (a.get("notes") or ""))
    ]
    save_apps(data)
    print(f"Tracked {slug} → status=planned")
    print(f"Requires: {', '.join(requires)}")
    print(f"Next: edit applications.toml / letter, then just app-show {slug}")


def cmd_status(args: argparse.Namespace) -> None:
    if args.status not in STATUSES:
        sys.exit(f"status must be one of: {', '.join(STATUSES)}")
    data = load_apps()
    app = find_app(data["applications"], args.slug)
    old = app.get("status")
    app["status"] = args.status
    if args.status == "shipped" and not app.get("shipped_on"):
        app["shipped_on"] = date.today().isoformat()
    if args.notes is not None:
        app["notes"] = args.notes
    save_apps(data)
    print(f"{args.slug}: {old} → {args.status}")


def cmd_ship(args: argparse.Namespace) -> None:
    data = load_apps()
    app = find_app(data["applications"], args.slug)
    letter = ROOT / app.get("letter", f"letters/{args.slug}.tex")
    if not letter.is_file():
        sys.exit(f"Letter missing: {letter}")
    if not args.skip_build:
        print(f"Building {letter.relative_to(ROOT)} …")
        subprocess.run(["latexmk", "-pdf", "-cd", str(letter)], check=True)
    app["status"] = "shipped"
    app["shipped_on"] = date.today().isoformat()
    save_apps(data)
    print(f"Marked {args.slug} shipped on {app['shipped_on']}")
    print()
    cmd_show(argparse.Namespace(slug=args.slug, checklist_only=False))


def cmd_show(args: argparse.Namespace) -> None:
    data = load_apps()
    app = find_app(data["applications"], args.slug)
    if not args.checklist_only:
        print(f"{app.get('institution')} — {app.get('department')}")
        print(f"Position:    {app.get('position')}")
        if app.get("requisition"):
            print(f"Requisition: {app.get('requisition')}")
        print(f"Slug:        {app.get('slug')}    Status: {app.get('status')}")
        print(f"When:        {format_when(app)}")
        if app.get("timing"):
            print(f"Timing:      {app.get('timing')}")
        if app.get("portal"):
            print(f"Apply at:    {app.get('portal')}")
        if app.get("ad_url"):
            print(f"Job ad:      {app.get('ad_url')}")
        if app.get("contact"):
            print(f"Contact:     {app.get('contact')}")
        if app.get("interfolio"):
            print(f"Interfolio:  {app.get('interfolio')}")
        if app.get("shipped_on"):
            print(f"Shipped:     {app.get('shipped_on')}")
        if app.get("notes"):
            print(f"Notes:       {app.get('notes')}")
        print()
    print("Materials → upload target")
    print(f"{'ID':<22} {'STATUS':<10} FILE / NOTE")
    print("-" * 72)
    for mid, label, dest, st in packet_rows(app):
        print(f"{mid:<22} {st:<10} {dest}")
        if label != mid:
            pass
    print()
    print("STATUS: ready = PDF present; need_pdf = .tex exists, build it; missing = not found; external = portal/Interfolio")
    sources = app.get("sources") or {}
    legacy = {k: app[k] for k in ("research", "teaching", "diversity", "mentoring") if app.get(k)}
    if sources or legacy:
        print("\nSource .tex overrides:")
        for k, v in {**legacy, **sources}.items():
            print(f"  {k}: {v}")


def cmd_set_field(args: argparse.Namespace) -> None:
    """Set a simple string field: portal, deadline, ad_url, notes, …"""
    data = load_apps()
    app = find_app(data["applications"], args.slug)
    field = args.field
    allowed = {
        "portal",
        "ad_url",
        "deadline",
        "review_begins",
        "timing",
        "timezone",
        "contact",
        "interfolio",
        "notes",
        "requisition",
        "position",
        "department",
        "institution",
    }
    if field not in allowed:
        sys.exit(f"field must be one of: {', '.join(sorted(allowed))}")
    if field == "timing" and args.value not in TIMINGS:
        sys.exit(f"timing must be one of: {', '.join(TIMINGS)}")
    app[field] = args.value
    save_apps(data)
    print(f"{args.slug}.{field} = {args.value!r}")


def cmd_requires(args: argparse.Namespace) -> None:
    data = load_apps()
    app = find_app(data["applications"], args.slug)
    req = [x.strip() for x in args.materials.split(",") if x.strip()]
    if not req:
        sys.exit("Provide comma-separated materials, e.g. cover_letter,cv,research_statement")
    unknown = [x for x in req if x not in MATERIAL_LABELS]
    if unknown:
        print(f"Note: non-standard ids {unknown} (allowed to proceed)", file=sys.stderr)
    app["requires"] = req
    upload = dict(app.get("upload") or {})
    defaults = default_upload(app["slug"], req)
    for mid in req:
        upload.setdefault(mid, defaults[mid])
    # Drop upload keys no longer required
    app["upload"] = {k: v for k, v in upload.items() if k in req}
    save_apps(data)
    print(f"{args.slug} requires = {req}")
    cmd_show(argparse.Namespace(slug=args.slug, checklist_only=True))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("list", help="List applications")
    p_list.add_argument("--status", choices=STATUSES, default=None)
    p_list.set_defaults(func=cmd_list)

    p_new = sub.add_parser("new", help="Create letter + tracker row")
    p_new.add_argument("institution", help='e.g. "University of Washington"')
    p_new.add_argument("department", nargs="?", default="", help='e.g. "Biology"')
    p_new.add_argument("--slug", default=None)
    p_new.add_argument("--position", default="Assistant Professor")
    p_new.add_argument("--deadline", default="", help="Optional hard or preferred date (YYYY-MM-DD)")
    p_new.add_argument(
        "--timing",
        default="",
        choices=("",) + TIMINGS,
        help="deadline | rolling | open_until_filled | review_begins | unknown (default: deadline if --deadline else unknown)",
    )
    p_new.add_argument("--review-begins", default="", help="For timing=review_begins")
    p_new.add_argument("--timezone", default="")
    p_new.add_argument("--portal", default="")
    p_new.add_argument("--ad-url", default="")
    p_new.add_argument("--contact", default="")
    p_new.add_argument("--interfolio", default="")
    p_new.add_argument("--requisition", default="")
    p_new.add_argument("--notes", default="")
    p_new.add_argument(
        "--require",
        action="append",
        default=[],
        help="Material id or comma-list; repeatable. Default from config.toml [defaults].requires",
    )
    p_new.add_argument("--force", action="store_true")
    p_new.set_defaults(func=cmd_new)

    p_st = sub.add_parser("status", help="Set status for a slug")
    p_st.add_argument("slug")
    p_st.add_argument("status", choices=STATUSES)
    p_st.add_argument("--notes", default=None)
    p_st.set_defaults(func=cmd_status)

    p_ship = sub.add_parser("ship", help="Build letter PDF and mark shipped")
    p_ship.add_argument("slug")
    p_ship.add_argument("--skip-build", action="store_true")
    p_ship.set_defaults(func=cmd_ship)

    p_show = sub.add_parser("show", help="Show where/when/what + file checklist")
    p_show.add_argument("slug")
    p_show.add_argument("--checklist-only", action="store_true")
    p_show.set_defaults(func=cmd_show)

    p_set = sub.add_parser("set", help="Set portal/deadline/ad_url/notes/…")
    p_set.add_argument("slug")
    p_set.add_argument("field")
    p_set.add_argument("value")
    p_set.set_defaults(func=cmd_set_field)

    p_req = sub.add_parser("requires", help="Replace requires list (comma-separated)")
    p_req.add_argument("slug")
    p_req.add_argument("materials", help="e.g. cover_letter,cv,research_statement,teaching_statement")
    p_req.set_defaults(func=cmd_requires)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

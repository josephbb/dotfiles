# Cover letters (per university)

Each search gets its own letter file and a row in `applications.toml`.

```bash
just app-new "University of Washington" Biology --slug uw-biology --deadline 2026-10-15
# edits letters/uw-biology.tex + tracker row (status=planned)

just app-status uw-biology in_progress
just letter uw-biology
just app-status uw-biology done
just ship uw-biology          # build PDF + status=shipped
just status
```

`_template.tex` is the skeleton only. Prefer `just app-new` over copying by hand so tracking stays in sync.

Keep institution-specific fit in the letter; keep research/teaching statements shared unless you add per-app override paths in `applications.toml`.

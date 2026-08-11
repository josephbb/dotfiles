# Academic job application materials

Package for a faculty / academic search **cycle**: shared CV + statement templates, plus **per-university** letters and a tracker for where/when/what to submit.

**You write the prose.** Cursor helps with structure, formatting, and feedback (`AGENTS.md`).

## Create

```bash
nix flake new -t ~/dotfiles#latex ~/Projects/academic-job-2026
cd ~/Projects/academic-job-2026
direnv allow
```

## Configure

1. `config.toml` — applicant, CV source, shared statement toggles, default `requires`
2. `applications.toml` — one row per university (portal, deadline, required materials, file map)

```bash
just sync
just pdf

just app-new "University of Washington" Biology \
  --slug uw-biology \
  --timing rolling \
  --portal 'https://apool.uw.edu/…' \
  --ad-url 'https://…' \
  --contact 'search@bio.uw.edu'
# Or with a hard date: --deadline 2026-10-15  (implies timing=deadline)

just app-show uw-biology          # where / when / checklist
just app-set uw-biology notes 'Wants DEI + mentoring'
just app-requires uw-biology cover_letter,cv,research_statement,teaching_statement,diversity_statement,references

just app-status uw-biology in_progress
just letter uw-biology
just app-status uw-biology done
just ship uw-biology
just status
```

## Per-application record

| Field | Meaning |
|---|---|
| `portal` / `ad_url` | Where to apply / job ad |
| `timing` | `deadline` / `rolling` / `open_until_filled` / `review_begins` / `unknown` |
| `deadline` / `review_begins` / `timezone` | Optional dates (many searches have none) |
| `contact` / `interfolio` / `requisition` | Logistics |
| `requires` | What the ad asks for (material ids) |
| `upload` | Which PDF/path goes in which portal slot |
| `sources` | Optional per-app `.tex` overrides |
| `status` | `planned` → `in_progress` → `done` → `shipped` |

`just app-show <slug>` prints the checklist (`ready` / `need_pdf` / `missing` / `external`).

## Document templates

| Document | Path |
|---|---|
| CV | synced into `cv/` |
| Research / teaching / diversity / mentoring | `statements/` |
| Cover letter | `letters/<slug>.tex` (one per university) |

## Layout

```text
config.toml              # applicant, CV, defaults.requires
applications.toml        # per-uni: portal, deadline, requires, upload
cv/ statements/ letters/
scripts/apps.py          # status board + checklist
```

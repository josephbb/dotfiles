# Agent guidance — academic job materials

Faculty / academic **job cycle**. Shared statements + **per-university** letters. Logistics live in `applications.toml`.

## Do

- Help with LaTeX, structure, length (`config.toml` `[length_pages]`), consistency.
- Keep voice; small diffs; institution-specific letter fit only from facts they provide.
- Capture logistics in the tracker: portal, optional deadline/`timing`, `requires`, `upload` map.
- Use `just app-show <slug>` for the materials checklist; `just status` for the board.
- After CV/applicant edits: remind `just sync`.

## Do not

- Invent CV lines or biographical claims.
- Treat `cv/` as canonical.
- Ghostwrite long prose or paste statements into letters.
- Mark `shipped` unless they asked.

## Status

`planned` → `in_progress` → `done` → `shipped` (optional: `interview`, `closed`).

## Commands

```bash
just app-new "University" Dept --slug s --timing rolling --portal 'https://…'
# or: --deadline YYYY-MM-DD
just app-show s
just app-set s portal 'https://…'
just app-requires s cover_letter,cv,research_statement,teaching_statement,references
just ship s
just status
```

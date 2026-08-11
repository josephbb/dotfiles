# CV (external)

This folder is **filled by `just sync`** from `config.toml` — not a hand-edited stub.

Set one of:

```toml
[cv]
path = "~/Projects/your-cv/cv.tex"
```

or:

```toml
[cv]
github_repo = "you/cv-repo"
github_path = "cv.tex"
github_ref = "main"
```

Then `just sync` or `just cv`. Supporting files next to the main `.tex` are copied when possible. Prefer a self-contained CV (or its own repo) so this job package does not fork your vita.

# dotfiles

Declarative macOS setup for Joe’s machine via **[nix-darwin](https://github.com/nix-darwin/nix-darwin)** + **[home-manager](https://github.com/nix-community/home-manager)**. Edit config → `rebuild` → the laptop matches.

## Table of contents

- [Why this setup](#why-this-setup)
- [Quick start](#quick-start)
- [Repo layout](#repo-layout)
- [What’s installed](#whats-installed)
  - [GUI apps (Homebrew)](#gui-apps-homebrew)
  - [Dock](#dock)
  - [Shell & CLI](#shell--cli)
  - [Research stack](#research-stack)
  - [Editors](#editors)
  - [Fonts & themes](#fonts--themes)
- [Cheat sheets](#cheat-sheets)
  - [Aliases](#aliases)
  - [Everyday CLI](#everyday-cli)
  - [Git](#git)
  - [fzf](#fzf)
  - [tmux](#tmux)
  - [Docker / Colima](#docker--colima)
  - [Project templates](#project-templates)
  - [R / Quarto / LaTeX](#r--quarto--latex)
  - [Secrets (OpenAlex)](#secrets-openalex)
- [Data directories](#data-directories)
- [Secrets (agenix)](#secrets-agenix)
- [Zotero](#zotero)
- [Projects & templates](#projects--templates)
- [Optional: Ollama + Continue](#optional-ollama--continue)
- [Fresh Mac](#fresh-mac)
- [Raycast](#raycast)

---

## Why this setup

- **New Mac in an afternoon** — Determinate Nix + clone + `darwin-rebuild switch` restores CLI, shell, fonts, Dock, VS Code extensions, and apps.
- **Reproducible** — versions pinned in [`flake.lock`](flake.lock); not a drifting pile of brew installs.
- **Clear split**
  - **nix-darwin** — Homebrew casks, fonts, Dock/Finder, folder layout ([`hosts/`](hosts/); shared bits in [`hosts/common/`](hosts/common/))
  - **home-manager** — PATH packages, zsh, git, editors, secrets ([`home/`](home/))
  - **Project flakes + uv** — per-repo science stacks, not one global Python
- **Multi-host ready** — each machine is `hosts/<name>/` + `darwinConfigurations.<name>`; heavy research/Ollama are per-host feature flags
- **Research-shaped** — `~/Projects`, Proton-backed `~/Datasets/{raw,derived}`, local `scratch`, TeX Live, Zotero → bib, no conda.
- **Secrets stay encrypted** — API keys via [agenix](https://github.com/ryantm/agenix); Apple/Proton/`gh auth` stay interactive.

What this does *not* own: cloud account state, Keychron firmware (JSON backup only), Cursor (install separately; not flake-managed), or full macOS visual theming beyond Dock/defaults.

---

## Quick start

```bash
rebuild    # alias → scripts/rebuild.sh
```

Or:

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#macbook
```

[`scripts/rebuild.sh`](scripts/rebuild.sh) then runs safe cleanup: `brew cleanup`, nix GC, store optimise, and `ollama prune` if Ollama is present (**does not** pull models).

Toggle optional features: `feature status` · `feature-enable ollama` · `feature-disable research` ([`scripts/feature.sh`](scripts/feature.sh)). Use `DOTFILES_HOST=<name>` when managing a non-default host.

---

## Repo layout

```text
flake.nix                 # inputs, mkDarwin helper, templates
hosts/common/             # shared nix-darwin: fonts, Finder, Datasets dirs
hosts/macbook/            # this machine: casks, Dock, features.toml, projects.toml
home/                     # home-manager modules (shared; gated by features)
  packages.nix            # general CLI
  research.nix            # R / Quarto / TeX / just / duckdb / … ([research] feature)
  secrets.nix             # agenix wiring
  shell.nix               # zsh, starship, fzf, zoxide, tmux, Ghostty
  git.nix                 # git + gh + delta
  vscode.nix / firefox.nix / zotero.nix / ollama.nix
  editor-settings.nix     # VS Code userSettings
secrets/                  # encrypted .age files
secrets.nix               # agenix recipients (SSH public keys)
templates/                # scratch · bayes · openalex · r — see templates/README.md
scripts/                  # rebuild, feature, ollama-setup, ssh-key-backup
keychron/                 # keyboard profile backup only
```

**Add another Mac:** copy `hosts/macbook` → `hosts/<name>`, set `[research]` / `[ollama]` in that host’s `features.toml`, trim casks/Dock as needed, register `<name> = mkDarwin "<name>";` in [`flake.nix`](flake.nix). Rebuild with `DOTFILES_HOST=<name> rebuild`.

Default branch: **`main`**.

---

## What’s installed

### GUI apps (Homebrew)

Declared in [`hosts/macbook/default.nix`](hosts/macbook/default.nix):

| App | Role |
|---|---|
| [Ghostty](https://ghostty.org/) | Terminal |
| [Raycast](https://www.raycast.com/) | Launcher / window mgmt (hotkeys set in UI) |
| [Visual Studio Code](https://code.visualstudio.com/) | Primary editor (extensions via HM) |
| [Firefox](https://www.mozilla.org/firefox/) | Default browser + Zotero Connector |
| [Google Chrome](https://www.google.com/chrome/) | Secondary browser |
| [Chromium](https://www.chromium.org/) | Chromium browser |
| [Proton Drive](https://proton.me/drive) | Sync (Datasets raw/derived, SSH key backup) |
| [Proton VPN](https://protonvpn.com/) | VPN |
| [Proton Pass](https://proton.me/pass) | Password manager |
| [Obsidian](https://obsidian.md/) | Notes / PKM |
| [Zotero](https://www.zotero.org/) | Reference manager |
| [RStudio](https://posit.co/products/open-source/rstudio/) | R IDE — **only if** `[research] enabled` |
| [Zoom](https://zoom.us/) | Meetings |
| Signal, TIDAL | Chat / music |
| [AnkerWork](https://us.ankerwork.com/) | Webcam / mic accessory software |
| Ollama | Local LLMs — **only if** `[ollama] enabled` |

### Dock

Pinned (rebuild replaces the list): Firefox, Mail, Calendar, Ghostty, VS Code, Obsidian, Zotero, RStudio, Messages, Signal, Zoom, TIDAL, System Settings.

### Shell & CLI

From [`home/packages.nix`](home/packages.nix) + [`home/shell.nix`](home/shell.nix) + [`home/git.nix`](home/git.nix):

| Area | Tools |
|---|---|
| Shell | zsh, Oh My Zsh (`git`, `fzf`), Starship, autosuggestions, syntax highlighting |
| Navigation | `eza`, `zoxide` (`z`/`zi`), `fzf`, `tree` |
| Search / view | `ripgrep` (`rg`), `fd`, `bat`, `glow`, `jq`, `yq` |
| Git | `git`, `git-lfs`, `gh`, `lazygit`, **delta** diffs |
| Process | `htop`, `btop`, `tmux` |
| Containers | `colima`, `docker`, `docker-compose` |
| Databases | `postgresql` (`psql`, server binaries) |
| Python tooling | `uv`, `direnv`, `nix-direnv` |
| Nix | `nixfmt`, `nil` |
| Misc | `curl`, `wget`, `tldr`, `shellcheck`, `sl`, `agenix` |

### Research stack

From [`home/research.nix`](home/research.nix):

| Tool | Role |
|---|---|
| `just` | Task runner (simpler than Make) |
| `watchexec` | Re-run commands on file change |
| `sqlite` / `duckdb` | Quick tabular analysis |
| `R` + `radian` | R + nicer REPL |
| `quarto` / `pandoc` | Publishing |
| `texliveFull` | Full TeX Live (`latexmk`, pdflatex, bibtex, …) |

### Editors

**VS Code** — app via brew; settings/extensions in [`home/vscode.nix`](home/vscode.nix) (settings via [`home/editor-settings.nix`](home/editor-settings.nix)):

| Extension area | Packages |
|---|---|
| Python | Python, Pylance, debugpy, Jupyter, Ruff |
| Config / Nix | direnv, nix-ide, even-better-toml, vscode-yaml |
| Docs / git | PR GitHub, Git History, Markdown All in One |
| Papers | LaTeX Workshop, Code Spell Checker, LTeX |
| Blog | Astro, MDX, Prettier |
| Theme | Gruvbox Material Dark (always) |

**RStudio** — brew cask; uses nixpkgs `R` on PATH. Prefer `radian` in the terminal.

**Cursor** — not managed by this flake (install from [cursor.com](https://www.cursor.com/) if you want it).

### Fonts & themes

| Where | Theme / font |
|---|---|
| Ghostty | Gruvbox Material Dark · **IosevkaTerm Nerd Font** 14 |
| VS Code | Gruvbox Material Dark (hard contrast) · same font family 13 |
| System font | `nerd-fonts.iosevka-term` via nix-darwin |

---

## Cheat sheets

### Aliases

Declared in [`home/shell.nix`](home/shell.nix) (plus Zotero / secrets / Ollama modules):

| Alias | What it does |
|---|---|
| `ls` / `ll` / `la` | `eza` (long + git column) |
| `cat` | `bat` |
| `g` | `git` |
| `rebuild` | Apply flake + cleanup ([`scripts/rebuild.sh`](scripts/rebuild.sh)) |
| `feature` / `feature-enable` / `feature-disable` | Optional features ([`features.toml`](hosts/macbook/features.toml)) |
| `colima-start` | Start Docker VM (4 CPU / 8 GB / 60 GB disk) |
| `zot` / `zot-bib` / `zot-plugins` | Zotero helpers |
| `openalex-load` / `openalex-show-path` | Load / show OpenAlex env file |
| `overleaf-load` / `overleaf-show-path` | Load / show Overleaf Git token env |
| `ollama-setup` / `status` / `pull-defaults` / `prune` | Local LLM helpers (when enabled) |

Oh My Zsh also adds many short git aliases (`gst`, `gco`, `gd`, …). List with: `alias | rg '^g'`.

### Everyday CLI

| Command | Try this | Notes |
|---|---|---|
| `eza` | `eza -T` | Tree view |
| `bat README.md` | `bat -A file` | Syntax + pager; shows non-printing with `-A` |
| `fd pattern` | `fd -e py` | Fast find |
| `rg pattern` | `rg -n TODO` | Fast content search |
| `jq` | `jq . file.json` | JSON |
| `yq` | `yq '.key' file.yaml` | YAML (jq-like) |
| `z projects` | `zi` | Jump to frecent dirs / interactive |
| `tldr tar` | | Short examples vs full man pages |
| `glow README.md` | | Render markdown in terminal |
| `htop` / `btop` | | Process monitors |
| `nil` | | Nix LSP (used by VS Code) |
| `nixfmt` | `nixfmt file.nix` | Format Nix |

### Git

| Command | Notes |
|---|---|
| `g st` / `git st` | Short status (`status -sb`) |
| `g lg` | Compact graph log |
| `git diff` / `git show` | Paged via **delta** (line numbers on) |
| `lazygit` | TUI for stage/commit/push |
| `gh` | GitHub CLI (`git_protocol = ssh`) |

Config: [`home/git.nix`](home/git.nix).

### fzf

| Keys | Action |
|---|---|
| `Ctrl-R` | Fuzzy search command history |
| `Ctrl-T` | Fuzzy find a file; paste path |
| `Alt-C` | Fuzzy find a directory and `cd` |

### tmux

Prefix is **`Ctrl-a`** (then the key below). Config in [`home/shell.nix`](home/shell.nix).

| Keys | Action |
|---|---|
| `Ctrl-a c` | New window |
| `Ctrl-a ,` | Rename window |
| `Ctrl-a "` / `%` | Split horizontal / vertical (keeps cwd) |
| `Ctrl-a h/j/k/l` | Move between panes |
| `Ctrl-a z` | Zoom pane (toggle) |
| `Ctrl-a d` | Detach (session keeps running) |
| `Ctrl-a [` | Scroll / copy mode (`q` to quit) |

```bash
tmux new -s paper          # named session
tmux attach -t paper       # come back
tmux ls                    # list sessions
```

Good for long MCMC / pulls / watches; detach and reopen Ghostty later.

### Docker / Colima

No Docker Desktop — **Colima** provides the VM:

```bash
colima-start               # once per reboot / when needed
docker ps
docker compose up
colima stop
```

### Project templates

Full guide: [`templates/README.md`](templates/README.md).

```bash
nix flake new -t ~/dotfiles#scratch  ~/Projects/blog-note
nix flake new -t ~/dotfiles#bayes    ~/Projects/my-model
nix flake new -t ~/dotfiles#openalex ~/Projects/oa-industry-ties
nix flake new -t ~/dotfiles#r        ~/Projects/tidyverse-scratch
```

`#scratch` is the **default**. Former `#python` → **`#bayes`**. After create: `direnv allow` + `uv sync` (or `renv::init()` for R).

### R / Quarto / LaTeX

| Command | Notes |
|---|---|
| `radian` | Preferred R console |
| `R` | Stock R |
| `quarto preview` | Quarto projects |
| `latexmk -pdf paper.tex` | TeX Live via `texliveFull` |
| RStudio | GUI; Dock pin |
| `nix flake new -t ~/dotfiles#r …` | Project stub with renv |

Bib: LaTeX Workshop reads `~/References/` ([Zotero](#zotero)).

### Secrets (OpenAlex)

```bash
agenix -e secrets/openalex.env.age   # edit encrypted file
rebuild
openalex-load                        # source into current shell
echo "$OPENALEX_API_KEY"             # should be set
```

---

## Data directories

| Path | Where it lives | Purpose |
|---|---|---|
| `~/Projects` | Local | Git clones |
| `~/Datasets/raw` | → Proton Drive `Datasets/raw` | Immutable inputs (synced) |
| `~/Datasets/derived` | → Proton Drive `Datasets/derived` | Processed outputs (synced) |
| `~/Datasets/scratch` | Local only | Temp / wipeable cache (never sync) |
| `~/References` | Local | Zotero bib exports (`library.bib`) |

Symlinks keep `~/Datasets/raw` and `~/Datasets/derived` stable. If Proton Drive isn’t signed in, activation uses local folders until the next `rebuild` after the client appears.

**OpenAlex layout** ([`templates/openalex`](templates/openalex)): JSONL pages land in **scratch** as a wipeable cache; optionally promote to **raw** for provenance; compile to **Parquet** in **derived** (analysis source of truth). Optional `catalog.duckdb` is a rebuildable SQL view over those Parquets—not a server DB. Corpus filters use the same `[query.*]` TOML shape as LLMDiscourse (`years`, `works`, `journals`, `search`, …).

| Stage | Path | Role |
|---|---|---|
| Cache | `~/Datasets/scratch/<slug>/openalex/` | JSONL; safe to delete / re-fetch |
| Raw (optional) | `~/Datasets/raw/<slug>/openalex/` | Frozen harvest |
| Derived | `~/Datasets/derived/<slug>/openalex/` | `*.parquet` (+ optional DuckDB) |

```bash
openalex-load
uv run python scripts/fetch.py              # → scratch
uv run python scripts/fetch.py --promote    # also freeze → raw
uv run python scripts/compile.py --duckdb   # → derived
```

SSH key backup (for agenix / GitHub on a new Mac):  
`~/Library/CloudStorage/ProtonDrive-*/SSHKeys/` — refresh with [`scripts/ssh-key-backup.sh`](scripts/ssh-key-backup.sh).

---

## Secrets (agenix)

Encrypted files in git; decrypted at activation with `~/.ssh/id_ed25519`.

| File | Purpose |
|---|---|
| [`secrets.nix`](secrets.nix) | Recipients (SSH public keys) |
| [`secrets/openalex.env.age`](secrets/openalex.env.age) | OpenAlex credentials |
| [`secrets/overleaf-git.env.age`](secrets/overleaf-git.env.age) | Overleaf Git integration token |
| [`home/secrets.nix`](home/secrets.nix) | Wire secrets → env / aliases / Overleaf credential helper |

**New / second machine (preferred — rekey):** add the new host’s public key to `secrets.nix` → on an old machine `agenix --rekey` → commit → on the new machine restore private key → `rebuild`.

**Wipe recovery:** copy key from Proton `SSHKeys/` (see [Data directories](#data-directories)).

**Add another secret:** entry in `secrets.nix` → `agenix -e secrets/….age` → declare in `home/secrets.nix` → `rebuild`.

---

## Zotero

Cask + config in [`home/zotero.nix`](home/zotero.nix). Firefox Connector via [`home/firefox.nix`](home/firefox.nix).

| Path / command | Purpose |
|---|---|
| `~/References/` | Shared bib exports (`REFERENCES_DIR`) |
| `~/References/library.bib` | Canonical Better BibTeX target (`ZOTERO_BIB`) |
| `zot` / `zot-bib` / `zot-plugins` | Open / check bib / list managed plugins |

**Plugins (auto on rebuild):** [Better BibTeX](https://github.com/retorquere/zotero-better-bibtex), [Zoplicate](https://github.com/ChenglongMa/zoplicate), [Better Notes](https://github.com/windingwind/zotero-better-notes), [ZotMoov](https://github.com/wileyyugioh/zotmoov), [Actions & Tags](https://github.com/windingwind/zotero-actions-tags).

**One-time:** open Zotero once if brand new → `rebuild` for plugins → export Better BibLaTeX to `~/References/library.bib` with **Keep updated**. Use Zotero’s own sync for the library; don’t put the live Zotero data dir on Proton Drive.

**Mendeley import:** [Zotero guide](https://www.zotero.org/support/kb/mendeley_import) — prefer online importer over RIS/BibTeX dump.

---

## Projects & templates

**Auto-clone** on rebuild ([`hosts/macbook/projects.toml`](hosts/macbook/projects.toml)): only if the destination does **not** exist. Currently: `josephbb.github.io` enabled; `dotfiles` listed but disabled.

Flake starters: [`templates/README.md`](templates/README.md) (`scratch`, `bayes`, `openalex`, `r`).

---

## Optional: Ollama + Continue

Flag: [`hosts/macbook/features.toml`](hosts/macbook/features.toml) · wiring: [`home/ollama.nix`](home/ollama.nix).

```bash
feature-enable ollama && rebuild
ollama-setup                 # start, pull defaults, prune retired
```

| Role | Model |
|---|---|
| Primary coding / agent | `qwen3-coder-next` |
| General / agent | `llama3.3:70b-instruct-q4_K_M` |
| Faster coding alt | `qwen3-coder:30b-a3b-q8_0` |
| Autocomplete | `qwen2.5-coder:7b-base-q4_K_M` |

Tuned for **M5 Max / 128GB**. Continue v2 reads [`~/.continue/config.yaml`](home/ollama.nix) (not the old `config.json`). `rebuild` does **not** pull models; use `ollama-setup`. Disable: `feature-disable ollama` → `rebuild` (models left on disk).

If Continue’s Models UI shows empty Chat/Autocomplete/Edit slots, reload the VS Code window after `rebuild` so it picks up the managed `config.yaml`.

---

## Fresh Mac

1. Xcode CLT + [Determinate Nix](https://determinate.systems/).
2. Restore SSH key from Proton `SSHKeys/` (or generate new + rekey — [Secrets](#secrets-agenix)).
3. `gh auth login` / ensure GitHub SSH works; clone this **private** repo to `~/dotfiles`.
4. `sudo darwin-rebuild switch --flake ~/dotfiles#macbook`
5. Sign into Apple / Proton; confirm `gh auth status`; import Keychron profile if needed.
6. Open Zotero once, then `rebuild` again for plugins; `ollama-setup` if enabled.

---

## Raycast

Configured in the Raycast UI (not in the flake):

| Hotkey | Command |
|---|---|
| **⌃⌥← / →** | Left / Right Half |
| **⌃⌥U / I / J / K** | Corner quarters |
| **⌃⌥↵** | Reasonable Maximize |
| **⌃⌥⌫** | Undo |
| **⌘⇧S** | Snippets |

| Snippet | Expands to |
|---|---|
| `;sig` | Email signature |
| `;web` | `https://joebakcoleman.com` |
| `;email` | Contact address |
| `;gh` | `https://github.com/josephbb/` |
| `;arxiv` | `https://arxiv.org/abs/` |
| `;path` | `~/Projects/` or `~/Datasets/` |
| `;cite` / `;thanks` / `;avail` | Paper / mail stubs |

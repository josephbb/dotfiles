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
  - [Python projects](#python-projects)
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
  - **nix-darwin** — Homebrew casks, fonts, Dock/Finder, folder layout ([`hosts/macbook/`](hosts/macbook/))
  - **home-manager** — PATH packages, zsh, git, editors, secrets ([`home/`](home/))
  - **Project flakes + uv** — per-repo science stacks, not one global Python
- **Research-shaped** — `~/Projects`, Proton-backed `~/Datasets/{raw,derived}`, local `scratch`, TeX Live, Zotero → bib, no conda.
- **Secrets stay encrypted** — API keys via [agenix](https://github.com/ryantm/agenix); Apple/Proton/`gh auth` stay interactive.

What this does *not* own: cloud account state, Keychron firmware (JSON backup only), Cursor settings (separate from VS Code), or full macOS visual theming beyond Dock/defaults.

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

Toggle optional features: `feature status` · `feature-enable ollama` · `feature-disable ollama` ([`scripts/feature.sh`](scripts/feature.sh)).

---

## Repo layout

```text
flake.nix                 # inputs, darwinConfigurations.macbook, templates
hosts/macbook/            # nix-darwin: casks, fonts, Dock, features.toml, projects.toml
home/                     # home-manager modules
  packages.nix            # general CLI
  research.nix            # R / Quarto / TeX / just / duckdb / …
  secrets.nix             # agenix wiring
  shell.nix               # zsh, starship, fzf, zoxide, tmux, Ghostty
  git.nix                 # git + gh + delta
  vscode.nix / firefox.nix / zotero.nix / ollama.nix
secrets/                  # encrypted .age files
secrets.nix               # agenix recipients (SSH public keys)
templates/python/         # nix flake new -t ~/dotfiles#python …
scripts/                  # rebuild, feature, ollama-setup, ssh-key-backup
keychron/                 # keyboard profile backup only
```

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
| [Firefox](https://www.mozilla.org/firefox/) | Browser + Zotero Connector |
| [Proton Drive](https://proton.me/drive) | Sync (Datasets raw/derived, SSH key backup) |
| [Zotero](https://www.zotero.org/) | Reference manager |
| [RStudio](https://posit.co/products/open-source/rstudio/) | R IDE |
| Zoom, Signal, TIDAL | Meetings / chat / music |
| Ollama | Local LLMs — **only if** `[ollama] enabled` in [`features.toml`](hosts/macbook/features.toml) |

### Dock

Pinned (rebuild replaces the list): Firefox, Ghostty, VS Code, RStudio, Messages, Signal, Zoom, TIDAL, System Settings.

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

**VS Code** — app via brew; settings/extensions in [`home/vscode.nix`](home/vscode.nix):

| Extension area | Packages |
|---|---|
| Python | Python, Pylance, debugpy, Jupyter, Ruff |
| Config / Nix | direnv, nix-ide, even-better-toml, vscode-yaml |
| Docs / git | PR GitHub, Markdown All in One |
| Papers | LaTeX Workshop, Code Spell Checker, LTeX |
| Blog | Astro, MDX, Prettier |
| Theme | Everforest (follows macOS light/dark) |

**RStudio** — brew cask; uses nixpkgs `R` on PATH. Prefer `radian` in the terminal.

**Cursor** — not managed by this flake (separate settings/extensions).

### Fonts & themes

| Where | Theme / font |
|---|---|
| Ghostty | Everforest Dark Hard · **IosevkaTerm Nerd Font** 14 |
| VS Code | Everforest Dark/Light via `autoDetectColorScheme` · same font family 13 |
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

### Python projects

```bash
nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
cd ~/Projects/my-analysis
direnv allow               # loads flake env on cd (or: nix develop)
uv sync
./scripts/install_kernel.sh
```

Layout: `data/`, `output/`, `src/`, `analysis.ipynb`, `palettes.toml`. Stack via uv: numpy/scipy/pandas/polars/pymc/arviz/…. See [`templates/python`](templates/python).

**direnv:** if a project has `.envrc` with `use flake`, `cd` auto-loads the env after one `direnv allow`. You don’t need `nix develop` every time.

### R / Quarto / LaTeX

| Command | Notes |
|---|---|
| `radian` | Preferred R console |
| `R` | Stock R |
| `quarto preview` | Quarto projects |
| `latexmk -pdf paper.tex` | TeX Live via `texliveFull` |
| RStudio | GUI; Dock pin |

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
| `~/Datasets/scratch` | Local only | Temp / never sync |
| `~/References` | Local | Zotero bib exports (`library.bib`) |

Symlinks keep `~/Datasets/raw` and `~/Datasets/derived` stable. If Proton Drive isn’t signed in, activation uses local folders until the next `rebuild` after the client appears.

SSH key backup (for agenix / GitHub on a new Mac):  
`~/Library/CloudStorage/ProtonDrive-*/SSHKeys/` — refresh with [`scripts/ssh-key-backup.sh`](scripts/ssh-key-backup.sh).

---

## Secrets (agenix)

Encrypted files in git; decrypted at activation with `~/.ssh/id_ed25519`.

| File | Purpose |
|---|---|
| [`secrets.nix`](secrets.nix) | Recipients (SSH public keys) |
| [`secrets/openalex.env.age`](secrets/openalex.env.age) | OpenAlex credentials |
| [`home/secrets.nix`](home/secrets.nix) | Wire secrets → env / aliases |

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

**Python template:**

```bash
nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
```

See [Python projects](#python-projects) above.

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

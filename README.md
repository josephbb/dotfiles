# dotfiles

Declarative macOS setup for Joe’s machine via **nix-darwin** + **home-manager**.

## Why this setup

A single private repo is the source of truth for the machine. Edit config → `rebuild` → the laptop matches. That buys:

- **New Mac in an afternoon** — Install Determinate Nix, clone this repo, `darwin-rebuild switch`. CLI tools, shell, fonts, Dock, VS Code extensions, and app installs come back without a checklist of downloads.
- **Reproducible, not “snowflake”** — Versions are pinned in `flake.lock`. The same flake on another machine (or after a wipe) yields the same environment, instead of drifting Homebrew installs and forgotten prefs.
- **Clear split of concerns**
  - **nix-darwin** — system-ish: Homebrew casks, fonts, Dock/Finder defaults, folder layout
  - **home-manager** — your user env: packages on `PATH`, zsh/Starship, git, Ghostty config, VS Code settings/extensions
  - **Project flakes + uv** — per-repo science stacks (PyMC, etc.), not one giant global Python
- **Research-shaped defaults** — `~/Projects` for git, `~/Datasets` for bulky/scratch data (not in Drive sync), LaTeX via TeX Live, Jupyter kernels from project templates, no conda.
- **Editor ready for the real work** — VS Code ships with Python/Ruff/Jupyter, LaTeX Workshop, Astro/MDX/Prettier (blog), Nix/direnv — themes track macOS light/dark.
- **Portable identity, local secrets** — `gh`/git/SSH tooling is declared here; logins, Proton/Apple accounts, and API keys stay out of the flake (as they should).
- **Templates as muscle memory** — `nix flake new -t ~/dotfiles#python …` spins a barebones analysis repo (data/output/src, notebook, kernel script) instead of reinventing layout each paper.

What this does *not* try to own: cloud account state, Keychron firmware (JSON backup only), or full macOS visual theming beyond Dock/defaults.

## Apply

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#macbook
```

Or use the shell alias after the first successful switch: `rebuild`.

## Layout

```text
flake.nix              # inputs + darwinConfigurations.macbook + templates
hosts/macbook/         # nix-darwin: Homebrew casks, fonts, macOS defaults
home/                  # home-manager: CLI packages, zsh, starship, git, vscode
keychron/              # exported keyboard profiles (backup only)
templates/python/      # nix flake new -t ~/dotfiles#python …
```

## New research project

```bash
nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
cd ~/Projects/my-analysis
direnv allow    # or: nix develop
uv sync
./scripts/install_kernel.sh
```

Barebones layout: `data/`, `output/`, `src/`, `analysis.ipynb`, nix+uv (numpy/scipy/pandas/polars/pymc/arviz/…). See [`templates/python`](templates/python).

## LaTeX

`texlive.combined.scheme-full` is in home-manager (provides `latexmk`, pdflatex, bibtex, etc.). Pair with the LaTeX Workshop VS Code extension. First rebuild downloads a lot; later switches are incremental.

## Fresh Mac

1. Install Xcode CLT and [Determinate Nix](https://determinate.systems/).
2. Clone this **private** repo to `~/dotfiles` (needs GitHub auth first: `gh auth login` or SSH keys).
3. `sudo darwin-rebuild switch --flake ~/dotfiles#macbook`
4. Sign into Apple / Proton; confirm `gh auth status`; import Keychron profile.

The flake installs `gh` and git defaults so tooling is portable. **Account login and this private repo’s existence are one-time** — they cannot live in Nix (secrets / cloud identity). On a new machine you authenticate, clone, then rebuild.

## Data dirs

- `~/Projects` — git clones
- `~/Datasets/{raw,derived,scratch}` — large / temporary / never-on-GitHub data

## Shell cheat sheet

Aliases and tools declared in [`home/shell.nix`](home/shell.nix) (plus related CLI from [`home/packages.nix`](home/packages.nix)). Use this as a learning list over the first weeks.

### Aliases (ours)

| Alias | Runs | What you get |
|---|---|---|
| `ls` | `eza` | Modern directory listing (colors, icons-capable) |
| `ll` | `eza -l --git` | Long listing + git status column in repos |
| `la` | `eza -la --git` | Same as `ll`, including hidden files |
| `cat` | `bat` | File viewer with syntax highlighting / paging |
| `g` | `git` | Shorthand for git |
| `rebuild` | `sudo darwin-rebuild switch --flake ~/dotfiles#macbook` | Re-apply this flake after edits |

### Related tools (no alias — type the name)

| Command | Try this | Why |
|---|---|---|
| `eza --help` | `eza -T` | Tree view without a separate `tree` mental model |
| `bat README.md` | `bat -A file` | Show non-printing chars |
| `fd pattern` | `fd -e py` | Fast find (often nicer than `find`) |
| `rg pattern` | `rg -n TODO` | Fast search in file contents |
| `fzf` | see keybindings below | Fuzzy picker |
| `lazygit` | run inside a repo | TUI for git status/commit/push |
| `tldr cmd` | `tldr tar` | Short practical examples |
| `uv` | `uv --help` | Python envs / packages |
| `direnv` | needs `.envrc` in a project | Auto-load project env on `cd` |

### Fuzzy find (fzf) keybindings

After the flake is applied, in zsh:

| Keys | Action |
|---|---|
| `Ctrl-R` | Fuzzy search command history |
| `Ctrl-T` | Fuzzy find a file; paste path on the command line |
| `Alt-C` | Fuzzy find a directory and `cd` into it |

### Prompt & “magic” behavior

- **Starship** — prompt shows path, git branch/status, and Python when it sees `pyproject.toml` / `uv.lock`
- **Autosuggestions** — grey ghost text from history; accept with → (right arrow) or `End`
- **Syntax highlighting** — commands turn color as you type (valid vs unknown)
- **Oh My Zsh `git` plugin** — adds many short git aliases (`gst`, `gco`, `gd`, …). List them after apply with: `alias | rg '^g'`
- **direnv** — when a project has `.envrc` (often `use flake`), entering the directory loads the Nix/dev env automatically

### Ghostty + VS Code themes & font

Ghostty and VS Code follow **macOS light/dark appearance** with Everforest (dark hard / light medium). Font: **IosevkaTerm Nerd Font** (icons for the prompt; dense monospace for code).

VS Code extensions and settings are declared in [`home/vscode.nix`](home/vscode.nix)
(Python, Jupyter, Ruff, LaTeX, Astro/MDX, Nix, direnv, …). The app itself stays a Homebrew cask
for a stable `/Applications/Visual Studio Code.app` Dock path.

## Raycast window management

Configured in the Raycast UI (not in the flake). Current hotkeys:

| Hotkey | Command |
|---|---|
| **⌃⌥← / →** | Left Half / Right Half |
| **⌃⌥U / I / J / K** | Top-left / Top-right / Bottom-left / Bottom-right |
| **⌃⌥↵** (Return) | Reasonable Maximize |
| **⌃⌥⌫** (Delete) | Undo |

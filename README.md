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
hosts/macbook/         # nix-darwin: Homebrew casks, fonts, macOS defaults, features.toml
home/                  # home-manager: CLI packages, zsh, starship, git, firefox, vscode, zotero, ollama
keychron/              # exported keyboard profiles (backup only)
templates/python/      # nix flake new -t ~/dotfiles#python …
scripts/               # helpers (feature enable/disable, …)
```

## New research project

```bash
nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
cd ~/Projects/my-analysis
direnv allow    # or: nix develop
uv sync
./scripts/install_kernel.sh
```

Barebones layout: `data/`, `output/`, `src/`, `analysis.ipynb`, `palettes.toml` (named plot colors via `src.palettes`), nix+uv (numpy/scipy/pandas/polars/pymc[nutpie]/arviz/…). See [`templates/python`](templates/python).

## LaTeX

`texliveFull` is in home-manager (provides `latexmk`, pdflatex, bibtex, etc.). Pair with the LaTeX Workshop VS Code extension. First rebuild downloads a lot; later switches are incremental.

LaTeX Workshop reads shared bibliographies from `~/References/` (see [Zotero](#zotero)).

## Zotero

Zotero is installed via Homebrew cask ([`hosts/macbook/default.nix`](hosts/macbook/default.nix)). Config lives in [`home/zotero.nix`](home/zotero.nix).

| Path / env | Purpose |
|---|---|
| `~/References/` | Shared bib exports for papers (`REFERENCES_DIR`) |
| `~/References/library.bib` | Canonical auto-export target (`ZOTERO_BIB`) |
| `zot` | Open Zotero |
| `zot-bib` | Check whether `library.bib` exists and how large it is |
| `zot-plugins` | Print plugin repos managed by dotfiles |

Use **Firefox** (also in the flake) for the [Zotero Connector](https://www.zotero.org/download/connectors) browser extension.
Connector install is declarative via [`home/firefox.nix`](home/firefox.nix) (Firefox policy force-install).

### One-time setup after install

1. **Migrate from Mendeley** (recommended: Zotero’s built-in importer, not BibTeX/RIS export):
   - Confirm PDFs open at [mendeley.com](https://www.mendeley.com) (everything synced to Elsevier’s servers).
   - In Zotero: **File → Import → Mendeley Reference Manager (online import)** and log in.
   - Optionally disable Zotero auto-sync during the first import (`Zotero → Settings → Sync`).
   - Import into a dedicated collection (e.g. `Imported from Mendeley`); spot-check metadata, PDFs, folders, and highlights before deleting anything in Mendeley.
   - Group libraries: copy items into a personal Mendeley folder first — the importer cannot read group libraries directly.
   - Details: [Zotero Mendeley import guide](https://www.zotero.org/support/kb/mendeley_import)

2. **Plugins** (installed automatically on `rebuild` for existing Zotero profiles):
   - Managed in [`home/zotero.nix`](home/zotero.nix) from GitHub releases.
   - If Zotero has never been opened on this machine, open it once to create profiles, then `rebuild` again.
   - Current plugin set:
     - [Better BibTeX](https://github.com/retorquere/zotero-better-bibtex) — stable citekeys + auto-export
     - [Zoplicate](https://github.com/ChenglongMa/zoplicate) — duplicate detection/merge workflow
     - [Better Notes](https://github.com/windingwind/zotero-better-notes) — advanced note workflows
     - [ZotMoov](https://github.com/wileyyugioh/zotmoov) — attachment move/link management
     - [Actions & Tags](https://github.com/windingwind/zotero-actions-tags) — workflow automation
   - For LaTeX: **File → Export Library…** once, choose *Better BibLaTeX*, save to `~/References/library.bib`, then right-click export → **Keep updated**.
   - VS Code LaTeX Workshop already includes `~/References` in `bibDirs` ([`home/vscode.nix`](home/vscode.nix)).

3. **Sync**: Zotero’s own sync (300 MB free) for library + attachments; don’t put the live Zotero data directory on Proton Drive.

4. **Firefox Connector**:
   - Installed automatically by Home Manager policy on `rebuild`.
   - If Firefox was open during rebuild, quit/reopen Firefox once.
   - Confirm in `about:addons` that Zotero Connector is enabled.

In paper repos, cite with `\cite{key}` and either symlink `~/References/library.bib` or add a project-local `refs.bib` that `@`‑imports the shared library.

## Fresh Mac

1. Install Xcode CLT and [Determinate Nix](https://determinate.systems/).
2. Clone this **private** repo to `~/dotfiles` (needs GitHub auth first: `gh auth login` or SSH keys).
3. `sudo darwin-rebuild switch --flake ~/dotfiles#macbook`
4. Sign into Apple / Proton; confirm `gh auth status`; import Keychron profile.

The flake installs `gh` and git defaults so tooling is portable. **Account login and this private repo’s existence are one-time** — they cannot live in Nix (secrets / cloud identity). On a new machine you authenticate, clone, then rebuild.

## Auto-clone projects

`hosts/macbook/projects.toml` can declare repos that should exist in `~/Projects` after `rebuild`.
The activation script only clones when the destination folder does **not** already exist.

Example:

```toml
[[projects]]
name = "my-analysis"
url = "git@github.com:your-org/my-analysis.git"
dest = "my-analysis" # optional; defaults to name
enabled = true       # optional; defaults to true
```

Notes:

- Existing directories are never overwritten or pulled — active work is left alone.
- Clones run as your user (not root) during activation.
- Use SSH URLs if you already use SSH keys with GitHub.

## Optional features (Ollama)

Optional packages live behind flags in [`hosts/macbook/features.toml`](hosts/macbook/features.toml).
Rebuild cannot interactively ask yes/no — use the helper instead:

```bash
feature status
feature-enable ollama    # prompts, then writes enabled = true
feature-disable ollama
rebuild
```

When `[ollama] enabled = true`:

- Homebrew installs **`ollama-app`** (not `curl | sh`)
- VS Code gets the **Continue** extension
- `~/.continue/config.json` points at local Ollama with:

| Role | Model |
|---|---|
| Agent | `llama3.1:70b-instruct-q4_K_M` |
| Chat/Edit | `qwen2.5-coder:32b-instruct-q8_0` |
| Chat/Edit | `qwen3-coder:30b-a3b-q8_0` |
| Autocomplete | `qwen2.5-coder:7b-base-q4_K_M` |

After rebuild:

1. Open the **Ollama** app once (starts the local API on `http://localhost:11434`).
2. Pull weights (~110GB total; fine on 128GB RAM): `ollama-pull-defaults`
3. Check: `ollama-status`
4. In VS Code, open the Continue sidebar and pick the models above.

To turn it off later: `feature-disable ollama` → `rebuild` (models on disk are left alone).

## Data dirs

- `~/Projects` — git clones
- `~/Datasets/{raw,derived,scratch}` — large / temporary / never-on-GitHub data
- `~/References` — Zotero bib exports for LaTeX (`library.bib` via Better BibTeX)

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
| `zot` | `open -a Zotero` | Open Zotero |
| `feature` / `feature-enable` / `feature-disable` | `scripts/feature.sh …` | Opt in/out of optional features (prompts) |
| `ollama-pull-defaults` | `ollama pull …` (×3) | Download configured Continue models (when Ollama enabled) |

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
| `zot-bib` | run after BBT export | Show path and line count of `~/References/library.bib` |
| `ollama-status` | when Ollama enabled | API up/down + `ollama list` |

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

Ghostty stays on **Everforest Dark Hard** always. VS Code can still follow macOS light/dark with Everforest. Font: **IosevkaTerm Nerd Font**.

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
| **⌘⇧S** | Snippets (open / search) |

### Snippet ideas

| Keyword | Expands to |
|---|---|
| `;sig` | Email signature (Joe Bak-Coleman / UW / joebakcoleman.com) |
| `;web` | `https://joebakcoleman.com` |
| `;email` | Your preferred contact address |
| `;zoom` | Standing Zoom/meeting link (if you have one) |
| `;addr` | Mailing address for forms (if useful) |
| `;thanks` | Short polite close (“Thanks, Joe”) |
| `;avail` | “I’m free … — does that work?” scheduling line |
| `;cite` | `Bak-Coleman et al.` or a go-to paper citation stub |
| `;path` | `~/Projects/` or `~/Datasets/` |
| `;gh` | `https://github.com/josephbb/` |
| `;arxiv` | `https://arxiv.org/abs/` (cursor after for the id) |
| `;mu` / `;emdash` | `μ` / `—` (if you don’t use Raycast symbol search) |

# dotfiles

Declarative macOS setup for Joseph's machine via **nix-darwin** + **home-manager**.

## Apply

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#macbook
```

Or use the shell alias after the first successful switch: `rebuild`.

## Layout

```text
flake.nix              # inputs + darwinConfigurations.macbook
hosts/macbook/         # nix-darwin: Homebrew casks, fonts, macOS defaults
home/                  # home-manager: CLI packages, zsh, starship, git
keychron/              # exported keyboard profiles (backup only)
templates/project/     # research repo starter (flake + uv) — TBD
```

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

### Ghostty + VS Code themes

Ghostty and VS Code both follow **macOS light/dark appearance** with Everforest
(dark contrast hard / light contrast medium — closest to Ghostty’s shipped themes).

VS Code extensions and settings are declared in [`home/vscode.nix`](home/vscode.nix)
(Python, Jupyter, Ruff, Nix, direnv, etc.). The app itself stays a Homebrew cask
for a stable `/Applications/Visual Studio Code.app` Dock path.

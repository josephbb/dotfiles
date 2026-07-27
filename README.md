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
2. Clone this repo to `~/dotfiles`.
3. `sudo darwin-rebuild switch --flake ~/dotfiles#macbook`
4. Sign into Apple / Proton; `gh auth login`; import Keychron profile.

## Data dirs

- `~/Projects` — git clones
- `~/Datasets/{raw,derived,scratch}` — large / temporary / never-on-GitHub data

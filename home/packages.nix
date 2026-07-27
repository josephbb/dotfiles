{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Core CLI
    git
    git-lfs
    gh
    curl
    wget
    jq
    fzf
    ripgrep
    fd
    bat
    eza
    tree
    tmux
    htop
    btop
    lazygit
    glow
    tldr
    shellcheck

    # Python / reproducibility
    uv
    direnv
    nix-direnv

    # Docs / R ecosystem (CLI)
    quarto
    pandoc
    R

    # Nix ergonomics
    nixfmt-rfc-style
    nil
  ];
}

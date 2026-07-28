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
    sl

    # Python / reproducibility
    uv
    direnv
    nix-direnv

    # Docs / R ecosystem (CLI)
    quarto
    pandoc
    R

    # LaTeX (large first download; full TeX Live for papers/ArXiv)
    texliveFull

    # Nix ergonomics
    nixfmt
    nil
  ];
}

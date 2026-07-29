{ pkgs, ... }:
{
  # General shell/dev CLI. Research stack lives in research.nix.
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

    # Nix ergonomics
    nixfmt
    nil
  ];
}

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
    yq
    fzf
    ripgrep
    fd
    bat
    eza
    tree
    htop
    btop
    lazygit
    glow
    tldr
    shellcheck
    sl

    # Containers (Colima VM + Docker CLI; start with `colima start`)
    colima
    docker
    docker-compose

    # Python / reproducibility
    uv
    direnv
    nix-direnv

    # Nix ergonomics
    nixfmt
    nil
  ];
}

{ pkgs, ... }:
{
  # Analysis / papers / reproducibility CLI — separate from general shell tooling.
  home.packages = with pkgs; [
    # Task runner + file watching (pipelines, sims, paper builds)
    just
    watchexec

    # Quick tabular analysis
    sqlite
    duckdb

    # Docs / R / publishing
    # Terminal R stays nixpkgs (radian, renv flakes). RStudio uses CRAN via brew cask r-app.
    quarto
    pandoc
    R
    radianWrapper

    # LaTeX (large first download; full TeX Live for papers/ArXiv)
    texliveFull
  ];

  programs.zsh.shellAliases = {
    rstudio = "open -a RStudio";
  };
}

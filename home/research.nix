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
    quarto
    pandoc
    R
    radianWrapper

    # LaTeX (large first download; full TeX Live for papers/ArXiv)
    texliveFull
  ];

  # Terminal / `open --env` launches. Dock/Finder need the /usr/local/bin symlink
  # from hosts/common (RStudio ignores shell env when opened from the GUI).
  home.sessionVariables = {
    RSTUDIO_WHICH_R = "${pkgs.R}/bin/R";
  };

  programs.zsh.shellAliases = {
    rstudio = "open -a RStudio --env RSTUDIO_WHICH_R=\"$RSTUDIO_WHICH_R\"";
  };
}

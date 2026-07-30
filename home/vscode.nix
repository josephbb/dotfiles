{
  pkgs,
  config,
  lib,
  ...
}:
let
  editorSettings = import ./editor-settings.nix {
    homeDirectory = config.home.homeDirectory;
  };
in
{
  # Homebrew still installs the GUI app (stable /Applications path for Dock).
  # home-manager owns settings + extensions (shared Code user data).
  programs.vscode = {
    enable = true;
    # Avoid a second competing update UI; brew owns the app binary.
    package = pkgs.vscode;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # Python
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-toolsai.jupyter
        charliermarsh.ruff

        # Reproducibility / config
        mkhl.direnv
        jnoortheen.nix-ide
        tamasfe.even-better-toml
        redhat.vscode-yaml

        # Git / docs
        github.vscode-pull-request-github
        donjayamanne.githistory
        yzhang.markdown-all-in-one

        # LaTeX (papers: ArXiV.tex, latexmk, bib)
        james-yu.latex-workshop

        # Astro blog (josephbb.github.io): Astro + MDX + Prettier
        astro-build.astro-vscode
        unifiedjs.vscode-mdx
        esbenp.prettier-vscode

        # Prose / papers
        streetsidesoftware.code-spell-checker
        valentjn.vscode-ltex

        # Theme (nixpkgs — avoids Marketplace fetch / .obsolete fights)
        sainnhe.gruvbox-material
      ];

      userSettings = editorSettings;
    };
  };

  # VS Code marks HM-managed extensions obsolete when Marketplace installs collide.
  # Clear that file on activate so themes (and friends) stay loadable.
  home.activation.clearVscodeObsolete = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    obsolete="${config.home.homeDirectory}/.vscode/extensions/.obsolete"
    if [ -f "$obsolete" ]; then
      rm -f "$obsolete"
    fi
  '';
}

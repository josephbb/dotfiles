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
  # Home Manager owns extensions; VS Code owns the live settings file so
  # Settings Sync can persist preferences across machines.
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
        jdinhlife.gruvbox
      ];
    };
  };

  # Bootstrap defaults are kept in Nix, but the live settings file is left
  # writable for VS Code and Settings Sync to manage.
  home.file."Library/Application Support/Code/User/settings.nix-seed.json".text =
    builtins.toJSON editorSettings;

  # VS Code marks HM-managed extensions obsolete when Marketplace installs collide.
  # Clear that file on activate so themes (and friends) stay loadable.
  home.activation.clearVscodeObsolete = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    obsolete="${config.home.homeDirectory}/.vscode/extensions/.obsolete"
    if [ -f "$obsolete" ]; then
      rm -f "$obsolete"
    fi
  '';

  # Migrate the old Home Manager-managed symlink once, or seed a new install.
  # After this, settings.json is intentionally unmanaged so Settings Sync and
  # the VS Code UI can update it without being overwritten on rebuild.
  home.activation.mutableVscodeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json"
    seed="${config.home.homeDirectory}/Library/Application Support/Code/User/settings.nix-seed.json"
    if [ -L "$settings" ]; then
      echo "VS Code: migrating settings.json to a user-owned file"
      target="$(${pkgs.coreutils}/bin/readlink "$settings")"
      ${pkgs.coreutils}/bin/rm -f "$settings"
      ${pkgs.coreutils}/bin/cp "$target" "$settings"
      ${pkgs.coreutils}/bin/chmod u+w "$settings"
    elif [ ! -e "$settings" ]; then
      echo "VS Code: creating settings.json from Nix seed"
      ${pkgs.coreutils}/bin/cp "$seed" "$settings"
      ${pkgs.coreutils}/bin/chmod u+w "$settings"
    fi
  '';
}

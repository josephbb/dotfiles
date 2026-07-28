{ config, pkgs, ... }:
let
  referencesDir = "${config.home.homeDirectory}/References";
  libraryBib = "${referencesDir}/library.bib";
in
{
  # Shared env for shells, scripts, and LaTeX projects.
  home.sessionVariables = {
    REFERENCES_DIR = referencesDir;
    ZOTERO_BIB = libraryBib;
  };

  home.file."References/.gitkeep".text = "";

  programs.zsh = {
    shellAliases = {
      zot = "open -a Zotero";
    };

    initContent = ''
      # Zotero → LaTeX (paths declared in home/zotero.nix)
      zot-bib() {
        local dir="''${REFERENCES_DIR:-$HOME/References}"
        local bib="''${ZOTERO_BIB:-$HOME/References/library.bib}"
        ${pkgs.coreutils}/bin/ls -la "$dir" 2>/dev/null || true
        if [[ -f "$bib" ]]; then
          echo "Library bib: $bib"
          ${pkgs.coreutils}/bin/wc -l "$bib"
        else
          echo "No library.bib yet."
          echo "After Mendeley import: install Better BibTeX and auto-export to:"
          echo "  $bib"
        fi
      }
    '';
  };
}

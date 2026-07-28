{ config, pkgs, lib, ... }:
let
  referencesDir = "${config.home.homeDirectory}/References";
  libraryBib = "${referencesDir}/library.bib";
  zoteroPluginRepos = [
    "retorquere/zotero-better-bibtex"
    "ChenglongMa/zoplicate"
    "windingwind/zotero-better-notes"
    "wileyyugioh/zotmoov"
    "windingwind/zotero-actions-tags"
  ];
  zoteroPluginReposText = lib.concatStringsSep " " zoteroPluginRepos;
in
{
  # Shared env for shells, scripts, and LaTeX projects.
  home.sessionVariables = {
    REFERENCES_DIR = referencesDir;
    ZOTERO_BIB = libraryBib;
  };

  home.file."References/.gitkeep".text = "";

  # Install selected Zotero plugins into existing profiles on activation.
  # Safe to re-run: existing plugin files are overwritten in place.
  home.activation.installZoteroPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zotero_base="$HOME/Library/Application Support/Zotero"
    profiles_dir="$zotero_base/Profiles"
    repos="${zoteroPluginReposText}"

    if [ ! -d "$profiles_dir" ]; then
      echo "Zotero: no profiles yet, skipping plugin install (open Zotero once first)."
      exit 0
    fi

    for repo in $repos; do
      release_api="https://api.github.com/repos/$repo/releases/latest"
      plugin_name="$(${pkgs.coreutils}/bin/basename "$repo")"
      tmp_xpi="$(${pkgs.coreutils}/bin/mktemp -t "zotero-plugin.XXXXXX.xpi")"

      download_url="$(${pkgs.curl}/bin/curl -fsSL "$release_api" | ${pkgs.jq}/bin/jq -r '.assets[] | select(.name | endswith(".xpi")) | .browser_download_url' | ${pkgs.coreutils}/bin/head -n1)"

      if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo "Zotero: $plugin_name has no .xpi asset in latest release, skipping."
        ${pkgs.coreutils}/bin/rm -f "$tmp_xpi"
        continue
      fi

      if ! ${pkgs.curl}/bin/curl -fL "$download_url" -o "$tmp_xpi"; then
        echo "Zotero: failed downloading $plugin_name from $download_url, skipping."
        ${pkgs.coreutils}/bin/rm -f "$tmp_xpi"
        continue
      fi

      extension_id="$(${pkgs.unzip}/bin/unzip -p "$tmp_xpi" manifest.json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.browser_specific_settings.gecko.id // .applications.gecko.id // empty')"

      if [ -z "$extension_id" ]; then
        echo "Zotero: could not detect extension id for $plugin_name, skipping."
        ${pkgs.coreutils}/bin/rm -f "$tmp_xpi"
        continue
      fi

      for profile in "$profiles_dir"/*; do
        [ -d "$profile" ] || continue
        ${pkgs.coreutils}/bin/mkdir -p "$profile/extensions"
        target="$profile/extensions/$extension_id.xpi"
        ${pkgs.coreutils}/bin/cp "$tmp_xpi" "$target"
        echo "Zotero: installed $plugin_name ($extension_id) in $(basename "$profile")."
      done

      ${pkgs.coreutils}/bin/rm -f "$tmp_xpi"
    done

    echo "Zotero: plugin install step complete."
  '';

  programs.zsh = {
    shellAliases = {
      zot = "open -a Zotero";
      zot-plugins = "echo ${lib.escapeShellArg zoteroPluginReposText}";
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
          echo "After Mendeley import: configure Better BibTeX auto-export to:"
          echo "  $bib"
        fi
      }
    '';
  };
}

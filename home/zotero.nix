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
  # Dropping XPIs alone is not enough: Zotero only rescans extensions/ after
  # extensions.lastAppBuildId / lastAppVersion are cleared, and sideloaded
  # addons default to userDisabled unless autoDisableScopes is 0.
  home.activation.installZoteroPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zotero_base="$HOME/Library/Application Support/Zotero"
    profiles_dir="$zotero_base/Profiles"
    repos="${zoteroPluginReposText}"
    installed_ids=""

    if [ ! -d "$profiles_dir" ]; then
      echo "Zotero: no profiles yet, skipping plugin install (open Zotero once first)."
      exit 0
    fi

    if /usr/bin/pgrep -f '/Applications/Zotero.app/Contents/MacOS/zotero' >/dev/null 2>&1; then
      echo "Zotero: app is running — quit it, then rebuild (or reopen Zotero) so new plugins register."
    fi

    for repo in $repos; do
      release_api="https://api.github.com/repos/$repo/releases/latest"
      plugin_name="$(${pkgs.coreutils}/bin/basename "$repo")"
      tmp_xpi="$(${pkgs.coreutils}/bin/mktemp -t "zotero-plugin.XXXXXX.xpi")"

      download_url="$(${pkgs.curl}/bin/curl -fsSL "$release_api" | ${pkgs.jq}/bin/jq -r '[.assets[] | select(.name | endswith(".xpi")) | .browser_download_url][0] // empty')"

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

      extension_id="$(${pkgs.unzip}/bin/unzip -p "$tmp_xpi" manifest.json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.applications.zotero.id // .browser_specific_settings.gecko.id // .applications.gecko.id // empty')"

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
        ${pkgs.coreutils}/bin/chmod 644 "$target"
        echo "Zotero: installed $plugin_name ($extension_id) in $(basename "$profile")."
      done

      installed_ids="$installed_ids $extension_id"
      ${pkgs.coreutils}/bin/rm -f "$tmp_xpi"
    done

    for profile in "$profiles_dir"/*; do
      [ -d "$profile" ] || continue
      prefs="$profile/prefs.js"
      if [ -f "$prefs" ]; then
        /usr/bin/grep -v 'extensions.lastAppBuildId\|extensions.lastAppVersion\|extensions.autoDisableScopes' "$prefs" >"$prefs.tmp" || true
        echo 'user_pref("extensions.autoDisableScopes", 0);' >>"$prefs.tmp"
        ${pkgs.coreutils}/bin/mv "$prefs.tmp" "$prefs"
      fi

      ext_json="$profile/extensions.json"
      if [ -f "$ext_json" ] && [ -n "$(echo $installed_ids | ${pkgs.coreutils}/bin/tr -d ' ')" ]; then
        ids_json="$(printf '%s\n' $installed_ids | ${pkgs.jq}/bin/jq -R . | ${pkgs.jq}/bin/jq -s .)"
        ${pkgs.jq}/bin/jq --argjson ids "$ids_json" '
          .addons |= map(
            if (.id as $id | $ids | index($id) != null) then
              . + {userDisabled: false, active: true, seen: true}
            else . end
          )
        ' "$ext_json" >"$ext_json.tmp" && ${pkgs.coreutils}/bin/mv "$ext_json.tmp" "$ext_json"
      fi
    done

    echo "Zotero: plugin install step complete. Fully quit and reopen Zotero to load new plugins."
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

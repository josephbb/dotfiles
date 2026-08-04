{
  lib,
  pkgs,
  username,
  ...
}:
{
  # Determinate Nix manages the nix installation; don't let nix-darwin clobber it.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # Used for backwards compatibility; leave alone once set.
  system.stateVersion = 5;

  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
  };

  # Fonts available system-wide for Ghostty / editors.
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka-term
  ];

  # Sensible macOS defaults (host modules add Dock pins).
  system.defaults = {
    finder.FXPreferredViewStyle = "clmv";
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # Create standard working directories on activate.
  # Datasets: raw/derived live on Proton Drive (synced); scratch stays local-only.
  # Host modules append project clones via mkAfter.
  system.activationScripts.extraActivation.text = lib.mkBefore ''
    mkdir -p /Users/${username}/Projects
    mkdir -p /Users/${username}/Datasets/scratch
    mkdir -p /Users/${username}/References
    chown ${username}:staff /Users/${username}/Projects /Users/${username}/Datasets /Users/${username}/References
    chown -R ${username}:staff /Users/${username}/Datasets/scratch

    # Prefer Proton Drive for durable dataset tiers when the client folder exists.
    PD_ROOT=$(find /Users/${username}/Library/CloudStorage -maxdepth 1 -type d -name 'ProtonDrive-*-folder' 2>/dev/null | head -1 || true)
    if [ -n "$PD_ROOT" ]; then
      PD_DATASETS="$PD_ROOT/Datasets"
      mkdir -p "$PD_DATASETS/raw" "$PD_DATASETS/derived"
      chown -R ${username}:staff "$PD_DATASETS"

      for sub in raw derived; do
        target="$PD_DATASETS/$sub"
        link="/Users/${username}/Datasets/$sub"
        if [ -L "$link" ]; then
          # Already linked; refresh if it points elsewhere.
          current=$(readlink "$link" || true)
          if [ "$current" != "$target" ]; then
            rm -f "$link"
            ln -s "$target" "$link"
            chown -h ${username}:staff "$link"
          fi
        elif [ -d "$link" ]; then
          # Migrate any existing local contents onto Proton, then replace with symlink.
          echo "Datasets: migrating $sub -> Proton Drive"
          rsync -a "$link"/ "$target"/
          rm -rf "$link"
          ln -s "$target" "$link"
          chown -h ${username}:staff "$link"
        else
          ln -s "$target" "$link"
          chown -h ${username}:staff "$link"
        fi
      done
    else
      echo "Datasets: Proton Drive folder not found; using local raw/derived"
      mkdir -p /Users/${username}/Datasets/raw /Users/${username}/Datasets/derived
      chown -R ${username}:staff /Users/${username}/Datasets
    fi
  '';

  # Set Firefox as default browser (macOS may show a one-time confirmation dialog).
  system.activationScripts.postActivation.text = ''
    if [ -x /opt/homebrew/bin/defaultbrowser ]; then
      sudo -u ${username} /opt/homebrew/bin/defaultbrowser firefox || true
    fi
  '';
}

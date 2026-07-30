{
  lib,
  pkgs,
  username,
  features,
  ...
}:
let
  projectsManifest = builtins.fromTOML (builtins.readFile ./projects.toml);
  configuredProjects = projectsManifest.projects or [ ];
  enabledProjects = lib.filter (project: project.enabled or true) configuredProjects;
  projectCloneScript = lib.concatMapStringsSep "\n" (
    project:
    let
      destination = project.dest or project.name;
    in
    ''
      if [ -d "/Users/${username}/Projects/${destination}" ]; then
        echo "Projects: ${destination} exists, skipping clone."
      else
        echo "Projects: cloning ${project.url} -> ${destination}"
        sudo -u ${username} git clone "${project.url}" "/Users/${username}/Projects/${destination}"
      fi
    ''
  ) enabledProjects;
  ollamaEnabled = features.ollama.enabled or false;
  cursorEnabled = features.cursor.enabled or false;
in
{
  # Determinate Nix manages the nix installation; don't let nix-darwin clobber it.
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Used for backwards compatibility; leave alone once set.
  system.stateVersion = 5;

  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
  };

  # GUI apps via Homebrew (declared here; CLI comes from home-manager).
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    brews = [
      "defaultbrowser" # CLI used to set the default browser
    ];
    casks =
      [
        "ghostty"
        "raycast"
        "visual-studio-code"
        "firefox"
        "google-chrome"
        "proton-drive"
        "protonvpn"
        "proton-pass"
        "zotero"
        "obsidian"
        "rstudio"
        "zoom"
        "signal"
        "tidal"
        "ankerwork"
      ]
      ++ lib.optionals ollamaEnabled [
        # Prefer brew cask over curl|sh; ships app + CLI for local models.
        "ollama-app"
      ]
      ++ lib.optionals cursorEnabled [
        "cursor"
      ];
  };

  # Fonts available system-wide for Ghostty / editors.
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka-term
  ];

  # Sensible macOS defaults (light touch; expand later).
  system.defaults = {
    dock = {
      autohide = false;
      tilesize = 42; # default is 64; lower = smaller icons
      orientation = "bottom"; # change to "left" or "right" later if desired
      show-recents = false;
      # Curated pins only — rebuild replaces the Dock app list.
      persistent-apps =
        [
          "/Applications/Firefox.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Ghostty.app"
          "/Applications/Visual Studio Code.app"
        ]
        ++ lib.optionals cursorEnabled [
          "/Applications/Cursor.app"
        ]
        ++ [
          "/Applications/Obsidian.app"
          "/Applications/RStudio.app"
          "/System/Applications/Messages.app"
          "/Applications/Signal.app"
          "/Applications/zoom.us.app"
          "/Applications/TIDAL.app"
          "/System/Applications/System Settings.app"
        ];
      persistent-others = [ ];
    };
    finder.FXPreferredViewStyle = "clmv";
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # Create standard working directories on activate.
  # Datasets: raw/derived live on Proton Drive (synced); scratch stays local-only.
  system.activationScripts.extraActivation.text = ''
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

    ${projectCloneScript}
  '';

  # Set Firefox as default browser (macOS may show a one-time confirmation dialog).
  system.activationScripts.postActivation.text = ''
    if [ -x /opt/homebrew/bin/defaultbrowser ]; then
      sudo -u ${username} /opt/homebrew/bin/defaultbrowser firefox || true
    fi
  '';
}

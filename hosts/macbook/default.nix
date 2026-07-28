{
  pkgs,
  username,
  ...
}:
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
    casks = [
      "ghostty"
      "raycast"
      "visual-studio-code"
      "firefox"
      "proton-drive"
      "zotero"
      "rstudio"
      "zoom"
      "signal"
      "tidal"
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
      persistent-apps = [
        "/Applications/Firefox.app"
        "/Applications/Ghostty.app"
        "/Applications/Visual Studio Code.app"
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
  system.activationScripts.extraActivation.text = ''
    mkdir -p /Users/${username}/Projects
    mkdir -p /Users/${username}/Datasets/{raw,derived,scratch}
    mkdir -p /Users/${username}/References
    chown ${username}:staff /Users/${username}/Projects /Users/${username}/Datasets /Users/${username}/References
    chown -R ${username}:staff /Users/${username}/Datasets
  '';

  # Set Firefox as default browser (macOS may show a one-time confirmation dialog).
  system.activationScripts.postActivation.text = ''
    if [ -x /opt/homebrew/bin/defaultbrowser ]; then
      sudo -u ${username} /opt/homebrew/bin/defaultbrowser firefox || true
    fi
  '';
}

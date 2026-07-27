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
    casks = [
      "ghostty"
      "raycast"
      "visual-studio-code"
      "proton-drive"
      "zotero"
      "rstudio"
    ];
  };

  # Fonts available system-wide for Ghostty / editors.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Sensible macOS defaults (light touch; expand later).
  system.defaults = {
    dock.autohide = true;
    finder.FXPreferredViewStyle = "clmv";
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  # Create standard working directories on activate.
  system.activationScripts.extraActivation.text = ''
    mkdir -p /Users/${username}/Projects
    mkdir -p /Users/${username}/Datasets/{raw,derived,scratch}
    chown ${username}:staff /Users/${username}/Projects /Users/${username}/Datasets
    chown -R ${username}:staff /Users/${username}/Datasets
  '';
}

{
  lib,
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
  researchEnabled = features.research.enabled or true;
in
{
  imports = [ ../common ];

  nixpkgs.hostPlatform = "aarch64-darwin";

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
        "chromium"
        "proton-drive"
        "protonvpn"
        "proton-pass"
        "zotero"
        "obsidian"
        "zoom"
        "signal"
        "tidal"
        "ankerwork"
      ]
      ++ lib.optionals researchEnabled [
        "rstudio"
      ]
      ++ lib.optionals ollamaEnabled [
        # Prefer brew cask over curl|sh; ships app + CLI for local models.
        "ollama-app"
      ];
  };

  system.defaults.dock = {
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
        "/Applications/Obsidian.app"
        "/Applications/Zotero.app"
      ]
      ++ lib.optionals researchEnabled [
        "/Applications/RStudio.app"
      ]
      ++ [
        "/System/Applications/Messages.app"
        "/Applications/Signal.app"
        "/Applications/zoom.us.app"
        "/Applications/TIDAL.app"
        "/System/Applications/System Settings.app"
      ];
    persistent-others = [ ];
  };

  system.activationScripts.extraActivation.text = lib.mkAfter projectCloneScript;
}

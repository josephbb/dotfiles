{ username, features, lib, ... }:
{
  imports =
    [
      ./packages.nix
      ./secrets.nix
      ./shell.nix
      ./git.nix
      ./firefox.nix
      ./vscode.nix
      ./zotero.nix
      ./ollama.nix
    ]
    ++ lib.optionals (features.research.enabled or true) [
      ./research.nix
    ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Bump when home-manager release notes say so.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # XDG so configs land in ~/.config
  xdg.enable = true;
}

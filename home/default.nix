{ username, ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./vscode.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # Bump when home-manager release notes say so.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # XDG so configs land in ~/.config
  xdg.enable = true;
}

{ ... }:
{
  programs.firefox = {
    enable = true;

    # Manage Firefox profile config declaratively (app binary still from Homebrew).
    profiles.default = {
      id = 0;
      isDefault = true;
    };

    policies = {
      # Keep extension installs predictable on new machines.
      ExtensionSettings = {
        "zotero@chnm.gmu.edu" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/zotero-connector/latest.xpi";
        };
      };
    };
  };
}

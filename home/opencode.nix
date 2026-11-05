{ config, pkgs, ... }:
let
  setupScript = "${config.home.homeDirectory}/dotfiles/scripts/opencode-setup.sh";
in
{
  # Pin in flake.lock: opencode 1.18.4, nono 0.68.0.
  # OpenCode 1 keeps tools in this process, so do not pass --standalone.
  # nono 0.68's registry pack is nolabs-ai/opencode (pulled by opencode-setup).
  programs.opencode.enable = true;

  home.packages = [ pkgs.nono ];

  # Extra grants go in filesystem here. extends keeps the pack's own paths.
  xdg.configFile."nono/profiles/opencode-local.json".text = ''
    {
      "extends": "nolabs-ai/opencode",
      "meta": {
        "name": "opencode-local",
        "version": "1.0.0"
      }
    }
  '';

  programs.zsh = {
    shellAliases = {
      opencode-setup = setupScript;
    };

    initContent = ''
      # Sandboxed OpenCode. `command opencode` is the nix binary.
      # Provider keys come from OPENCODE_ENV_FILE (agenix), only for this process.
      opencode() {
        (
          if [[ -n "''${OPENCODE_ENV_FILE:-}" && -f "$OPENCODE_ENV_FILE" ]]; then
            set -a
            # shellcheck disable=SC1090
            source "$OPENCODE_ENV_FILE"
            set +a
          fi
          exec nono run --profile opencode-local -- command opencode "$@"
        )
      }
    '';
  };
}

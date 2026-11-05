{
  config,
  pkgs,
  agenix,
  ...
}:
let
  overleafGitCredential = pkgs.writeShellScript "overleaf-git-credential" ''
    set -euo pipefail
    case "''${1:-}" in
      get)
        env_file="''${OVERLEAF_GIT_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/overleaf-git-env}"
        if [[ ! -f "$env_file" ]]; then
          exit 0
        fi
        # shellcheck disable=SC1090
        set -a
        source "$env_file"
        set +a
        if [[ -z "''${OVERLEAF_GIT_TOKEN:-}" ]]; then
          exit 0
        fi
        echo "username=git"
        echo "password=''${OVERLEAF_GIT_TOKEN}"
        ;;
      *)
        exit 0
        ;;
    esac
  '';
in
{
  home.packages = [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets.openalex-env.file = ../secrets/openalex.env.age;
    secrets.tie-verify-env.file = ../secrets/tie-verify.env.age;
    secrets.overleaf-git-env.file = ../secrets/overleaf-git.env.age;
    secrets.altmetric-env.file = ../secrets/altmetric.env.age;
    secrets.cloudflare-env.file = ../secrets/cloudflare.env.age;
    secrets.opencode-env.file = ../secrets/opencode.env.age;
  };

  home.sessionVariables = {
    OPENALEX_ENV_FILE = config.age.secrets.openalex-env.path;
    TIE_VERIFY_ENV_FILE = config.age.secrets.tie-verify-env.path;
    OVERLEAF_GIT_ENV_FILE = config.age.secrets.overleaf-git-env.path;
    ALTMETRIC_ENV_FILE = config.age.secrets.altmetric-env.path;
    CLOUDFLARE_ENV_FILE = config.age.secrets.cloudflare-env.path;
    OPENCODE_ENV_FILE = config.age.secrets.opencode-env.path;
  };

  # ''${  => literal ${ for the shell (bash parameter expansion)
  programs.zsh.shellAliases = {
    openalex-load = ''source "''${OPENALEX_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/openalex-env}"'';
    openalex-show-path = ''echo "''${OPENALEX_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/openalex-env}"'';
    tie-verify-load = ''source "''${TIE_VERIFY_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/tie-verify-env}"'';
    tie-verify-show-path = ''echo "''${TIE_VERIFY_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/tie-verify-env}"'';
    overleaf-load = ''source "''${OVERLEAF_GIT_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/overleaf-git-env}"'';
    overleaf-show-path = ''echo "''${OVERLEAF_GIT_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/overleaf-git-env}"'';
    altmetric-load = ''source "''${ALTMETRIC_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/altmetric-env}"'';
    altmetric-show-path = ''echo "''${ALTMETRIC_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/altmetric-env}"'';
    cloudflare-load = ''source "''${CLOUDFLARE_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/cloudflare-env}"'';
    cloudflare-show-path = ''echo "''${CLOUDFLARE_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/cloudflare-env}"'';
    opencode-load = ''source "''${OPENCODE_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/opencode-env}"'';
    opencode-show-path = ''echo "''${OPENCODE_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/opencode-env}"'';
  };

  programs.git.settings = {
    # Overleaf expects username embedded as https://git@git.overleaf.com/...
    "url.https://git@git.overleaf.com/".insteadOf = "https://git.overleaf.com/";
    "credential.https://git.overleaf.com".helper = toString overleafGitCredential;
    "credential.https://git@git.overleaf.com".helper = toString overleafGitCredential;
  };
}

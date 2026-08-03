{
  config,
  pkgs,
  agenix,
  ...
}:
{
  home.packages = [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets.openalex-env.file = ../secrets/openalex.env.age;
    secrets.tie-verify-env.file = ../secrets/tie-verify.env.age;
  };

  home.sessionVariables = {
    OPENALEX_ENV_FILE = config.age.secrets.openalex-env.path;
    TIE_VERIFY_ENV_FILE = config.age.secrets.tie-verify-env.path;
  };

  programs.zsh.shellAliases = {
    openalex-load = ''source "${OPENALEX_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/openalex-env}"'';
    openalex-show-path = ''echo "${OPENALEX_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/openalex-env}"'';
    tie-verify-load = ''source "${TIE_VERIFY_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/tie-verify-env}"'';
    tie-verify-show-path = ''echo "${TIE_VERIFY_ENV_FILE:-$(getconf DARWIN_USER_TEMP_DIR)/agenix/tie-verify-env}"'';
  };
}

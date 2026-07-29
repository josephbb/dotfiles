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
  };

  home.sessionVariables = {
    OPENALEX_ENV_FILE = config.age.secrets.openalex-env.path;
  };

  programs.zsh.shellAliases = {
    openalex-load = ''source "$OPENALEX_ENV_FILE"'';
    openalex-show-path = ''echo "$OPENALEX_ENV_FILE"'';
  };
}

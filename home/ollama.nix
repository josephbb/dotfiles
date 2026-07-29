{
  features,
  lib,
  pkgs,
  config,
  ...
}:
let
  ollamaEnabled = features.ollama.enabled or false;
  continueConfig = {
    models = [
      {
        title = "Qwen3-Coder-Next (Primary coding / agent)";
        provider = "ollama";
        model = "qwen3-coder-next";
        apiBase = "http://localhost:11434";
      }
      {
        title = "Llama 3.3 70B (General / agent)";
        provider = "ollama";
        model = "llama3.3:70b-instruct-q4_K_M";
        apiBase = "http://localhost:11434";
      }
      {
        title = "Qwen3 Coder 30B (Faster coding alt)";
        provider = "ollama";
        model = "qwen3-coder:30b-a3b-q8_0";
        apiBase = "http://localhost:11434";
      }
    ];
    tabAutocompleteModel = {
      title = "Qwen 2.5 Coder 7B (Fast Autocomplete)";
      provider = "ollama";
      model = "qwen2.5-coder:7b-base-q4_K_M";
      apiBase = "http://localhost:11434";
    };
  };
  setupScript = "${config.home.homeDirectory}/dotfiles/scripts/ollama-setup.sh";
in
lib.mkIf ollamaEnabled {
  # Continue.dev ↔ local Ollama
  home.file.".continue/config.json".text = builtins.toJSON continueConfig;

  programs.vscode.profiles.default.extensions = [
    pkgs.vscode-extensions.continue.continue
  ];

  programs.zsh = {
    shellAliases = {
      ollama-setup = setupScript;
      ollama-pull-defaults = "${setupScript} pull";
      ollama-prune = "${setupScript} prune";
      ollama-status = "${setupScript} status";
    };
  };
}

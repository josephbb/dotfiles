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
        title = "Llama 3.1 70B (Agent)";
        provider = "ollama";
        model = "llama3.1:70b-instruct-q4_K_M";
        apiBase = "http://localhost:11434";
      }
      {
        title = "Qwen 2.5 Coder 32B (Chat/Edit)";
        provider = "ollama";
        model = "qwen2.5-coder:32b-instruct-q8_0";
        apiBase = "http://localhost:11434";
      }
      {
        title = "Qwen3 Coder 30B (Chat/Edit)";
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
  defaultModels = [
    "llama3.1:70b-instruct-q4_K_M"
    "qwen2.5-coder:32b-instruct-q8_0"
    "qwen3-coder:30b-a3b-q8_0"
    "qwen2.5-coder:7b-base-q4_K_M"
  ];
in
lib.mkIf ollamaEnabled {
  # Continue.dev ↔ local Ollama
  home.file.".continue/config.json".text = builtins.toJSON continueConfig;

  programs.vscode.profiles.default.extensions = [
    pkgs.vscode-extensions.continue.continue
  ];

  programs.zsh = {
    shellAliases = {
      ollama-pull-defaults = lib.concatStringsSep " && " (
        map (m: "ollama pull ${lib.escapeShellArg m}") defaultModels
      );
    };

    initContent = ''
      ollama-status() {
        if command -v ollama >/dev/null 2>&1; then
          echo "Ollama binary: $(command -v ollama)"
          curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1 \
            && echo "API: up (http://localhost:11434)" \
            || echo "API: down — open the Ollama app, then retry"
          ollama list 2>/dev/null || true
        else
          echo "Ollama not on PATH. Enable [ollama] in hosts/macbook/features.toml and rebuild."
        fi
      }
    '';
  };
}

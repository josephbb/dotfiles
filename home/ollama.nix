{
  features,
  lib,
  pkgs,
  config,
  ...
}:
let
  ollamaEnabled = features.ollama.enabled or false;
  # Continue v2+ reads config.yaml (config.json is deprecated / ignored when yaml exists).
  # Model tags must match `ollama list` exactly.
  continueConfigYaml = ''
    name: Local Ollama
    version: 0.0.1
    schema: v1
    models:
      - name: Qwen3-Coder-Next (Primary coding / agent)
        provider: ollama
        model: qwen3-coder-next:latest
        apiBase: http://localhost:11434
        roles:
          - chat
          - edit
          - apply
        capabilities:
          - tool_use
      - name: Llama 3.3 70B (General / agent)
        provider: ollama
        model: llama3.3:70b-instruct-q4_K_M
        apiBase: http://localhost:11434
        roles:
          - chat
          - edit
          - apply
        capabilities:
          - tool_use
      - name: Qwen3 Coder 30B (Faster coding alt)
        provider: ollama
        model: qwen3-coder:30b-a3b-q8_0
        apiBase: http://localhost:11434
        roles:
          - chat
          - edit
          - apply
        capabilities:
          - tool_use
      - name: Qwen 2.5 Coder 7B (Fast Autocomplete)
        provider: ollama
        model: qwen2.5-coder:7b-base-q4_K_M
        apiBase: http://localhost:11434
        roles:
          - autocomplete
  '';
  setupScript = "${config.home.homeDirectory}/dotfiles/scripts/ollama-setup.sh";
in
lib.mkIf ollamaEnabled {
  # Continue.dev ↔ local Ollama (v2 local-only config)
  home.file.".continue/config.yaml".text = continueConfigYaml;

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

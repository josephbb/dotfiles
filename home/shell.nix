{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    # Lock current behavior (zsh files in $HOME) before HM 26.05 default flip.
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
      ];
      # Starship owns the prompt; leave OMZ theme empty.
      theme = "";
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -l --git";
      la = "eza -la --git";
      cat = "bat";
      g = "git";
      rebuild = "sudo darwin-rebuild switch --flake ~/dotfiles#macbook";
      feature = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh";
      feature-enable = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh enable";
      feature-disable = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh disable";
    };

    initContent = ''
      # nix-direnv
      eval "$(direnv hook zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      python = {
        detect_extensions = [ "py" ];
        detect_files = [
          "pyproject.toml"
          ".python-version"
          "uv.lock"
        ];
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Ghostty config (app itself is a Homebrew cask).
  # Always dark — does not follow macOS appearance.
  xdg.configFile."ghostty/config".text = ''
    font-family = IosevkaTerm Nerd Font
    font-size = 14
    theme = Everforest Dark Hard
    macos-option-as-alt = true
    window-padding-x = 8
    window-padding-y = 6
    copy-on-select = clipboard
  '';
}

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
      rebuild = "${config.home.homeDirectory}/dotfiles/scripts/rebuild.sh";
      feature = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh";
      feature-enable = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh enable";
      feature-disable = "${config.home.homeDirectory}/dotfiles/scripts/feature.sh disable";
      # Containers: start the Colima VM, then use docker as usual
      colima-start = "colima start --cpu 4 --memory 8 --disk 60";
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

  # Jump to frecent directories: `z projects`, `zi` for interactive.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Persistent sessions for long jobs (MCMC, pulls, watches). Prefix: Ctrl-a.
  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      set -g renumber-windows on
      set -g status-position bottom
      set -g status-left-length 40
      set -g status-left '#[bold]#S#[default] '
      set -g status-right '%Y-%m-%d %H:%M '
      set -g status-style 'bg=default,fg=colour246'
      set -g window-status-current-style 'fg=colour223,bold'
      set -g pane-border-style 'fg=colour238'
      set -g pane-active-border-style 'fg=colour142'

      # Splits inherit current path
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Vim-ish pane movement
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };

  # Ghostty config (app itself is a Homebrew cask).
  # Always dark — does not follow macOS appearance.
  xdg.configFile."ghostty/config".text = ''
    font-family = IosevkaTerm Nerd Font
    font-size = 14
    theme = Gruvbox Material Dark
    macos-option-as-alt = true
    window-padding-x = 8
    window-padding-y = 6
    copy-on-select = clipboard
  '';
}

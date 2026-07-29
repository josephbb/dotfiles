{ ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "Joe Bak-Coleman";
        email = "jbakcoleman@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "code --wait";
      fetch.prune = true;
      diff.colorMoved = "default";
      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate -20";
      };
    };

    ignores = [
      ".DS_Store"
      ".venv/"
      "__pycache__/"
      ".direnv/"
      ".Rproj.user/"
      ".Rhistory"
      "*.pyc"
      ".ipynb_checkpoints/"
      ".mypy_cache/"
      ".ruff_cache/"
      ".pytest_cache/"
    ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}

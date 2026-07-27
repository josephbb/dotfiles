{ pkgs, ... }:
let
  everforest = pkgs.vscode-utils.extensionFromVscodeMarketplace {
    name = "everforest";
    publisher = "sainnhe";
    version = "0.3.0";
    sha256 = "sha256-nZirzVvM160ZTpBLTimL2X35sIGy5j2LQOok7a2Yc7U=";
  };
in
{
  # Homebrew still installs the GUI app (stable /Applications path for Dock).
  # home-manager owns settings + extensions (shared Code user data).
  programs.vscode = {
    enable = true;
    # Avoid a second competing update UI; brew owns the app binary.
    package = pkgs.vscode;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions =
        (with pkgs.vscode-extensions; [
          # Python
          ms-python.python
          ms-python.vscode-pylance
          ms-python.debugpy
          ms-toolsai.jupyter
          charliermarsh.ruff

          # Reproducibility / config
          mkhl.direnv
          jnoortheen.nix-ide
          tamasfe.even-better-toml
          redhat.vscode-yaml

          # Git / docs
          github.vscode-pull-request-github
          yzhang.markdown-all-in-one

          # LaTeX (papers: ArXiV.tex, latexmk, bib)
          james-yu.latex-workshop

          # Astro blog (josephbb.github.io): Astro + MDX + Prettier
          astro-build.astro-vscode
          unifiedjs.vscode-mdx
          esbenp.prettier-vscode

          # Prose / papers
          streetsidesoftware.code-spell-checker
          valentjn.vscode-ltex
        ])
        ++ [ everforest ];

      userSettings = {
        # Match Ghostty: Everforest + macOS light/dark
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" = "Everforest Dark";
        "workbench.preferredLightColorTheme" = "Everforest Light";
        "everforest.darkContrast" = "hard";
        "everforest.lightContrast" = "medium";
        "everforest.darkItalic" = true;
        "everforest.lightItalic" = true;

        "editor.fontFamily" = "JetBrainsMono Nerd Font, Menlo, Monaco, 'Courier New', monospace";
        "editor.fontSize" = 13;
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "editor.rulers" = [ 88 ];

        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.exclude" = {
          "**/.direnv" = true;
          "**/.venv" = true;
          "**/__pycache__" = true;
          "**/.ruff_cache" = true;
          "**/.mypy_cache" = true;
          "**/.pytest_cache" = true;
        };
        "files.watcherExclude" = {
          "**/.direnv/**" = true;
          "**/.venv/**" = true;
          "**/Datasets/**" = true;
        };

        # Prefer project .venv / uv env when present; don't hardcode a global interpreter
        "python.analysis.typeCheckingMode" = "standard";
        "python.terminal.activateEnvironment" = true;

        "notebook.formatOnSave.enabled" = true;
        "notebook.codeActionsOnSave" = {
          "notebook.source.fixAll" = "explicit";
        };

        "direnv.restart.automatic" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";

        # LaTeX Workshop → latexmk (matches your paper repos)
        "latex-workshop.latex.tools" = [
          {
            name = "latexmk";
            command = "latexmk";
            args = [
              "-pdf"
              "-interaction=nonstopmode"
              "-synctex=1"
              "-file-line-error"
              "%DOC%"
            ];
          }
        ];
        "latex-workshop.latex.recipes" = [
          {
            name = "latexmk";
            tools = [ "latexmk" ];
          }
        ];
        "latex-workshop.view.pdf.viewer" = "tab";

        # Prettier for the Astro blog (and MD/MDX); Ruff stays for Python
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[astro]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[markdown]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[mdx]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll.ruff" = "explicit";
            "source.organizeImports.ruff" = "explicit";
          };
        };

        "workbench.startupEditor" = "none";
        "explorer.confirmDelete" = false;
      };
    };
  };
}

# Shared VS Code user settings (home/vscode.nix).
{ homeDirectory }:
{
  # Always dark — match Ghostty (does not follow macOS appearance)
  "window.autoDetectColorScheme" = false;
  "workbench.colorTheme" = "Gruvbox Material Dark";
  "gruvboxMaterial.darkContrast" = "hard";
  "gruvboxMaterial.italicComments" = true;

  "editor.fontFamily" = "IosevkaTerm Nerd Font, Menlo, Monaco, 'Courier New', monospace";
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
    "**/.mypy_cache" = true;
    "**/.ruff_cache" = true;
    "**/.pytest_cache" = true;
  };
  "search.exclude" = {
    "**/.direnv/**" = true;
    "**/.venv/**" = true;
  };

  "python.defaultInterpreterPath" = "python";
  "python.analysis.typeCheckingMode" = "basic";

  "direnv.restart.automatic" = true;
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nil";

  # LaTeX Workshop → latexmk (matches paper repos)
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
  # Shared bib export from Zotero (Better BibTeX → ~/References/library.bib)
  "latex-workshop.bibtex.bibDirs" = [
    "${homeDirectory}/References"
  ];

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
}

{
  features,
  lib,
  config,
  ...
}:
let
  cursorEnabled = features.cursor.enabled or false;
  editorSettings = import ./editor-settings.nix {
    homeDirectory = config.home.homeDirectory;
  };
  # Marketplace IDs mirroring home/vscode.nix (skip Continue — Cursor has its own agent).
  # Keep Pylance; Cursor also ships cursorpyright, which can coexist.
  cursorExtensions = [
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.debugpy"
    "ms-toolsai.jupyter"
    "charliermarsh.ruff"
    "mkhl.direnv"
    "jnoortheen.nix-ide"
    "tamasfe.even-better-toml"
    "redhat.vscode-yaml"
    "github.vscode-pull-request-github"
    "donjayamanne.githistory"
    "yzhang.markdown-all-in-one"
    "james-yu.latex-workshop"
    "astro-build.astro-vscode"
    "unifiedjs.vscode-mdx"
    "esbenp.prettier-vscode"
    "streetsidesoftware.code-spell-checker"
    "valentjn.vscode-ltex"
    "sainnhe.gruvbox-material"
  ];
  settingsJson = builtins.toJSON editorSettings;
in
lib.mkIf cursorEnabled {
  # Mirror VS Code user settings into Cursor.
  home.file."Library/Application Support/Cursor/User/settings.json".text = settingsJson + "\n";

  # Install / refresh Marketplace extensions after each activate.
  home.activation.cursorExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cursor_bin="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    if [ ! -x "$cursor_bin" ]; then
      echo "Cursor: app not found yet (brew cask installs on darwin-rebuild); skip extensions this run."
    else
      echo "Cursor: syncing extensions to match VS Code stack…"
      ${lib.concatMapStringsSep "\n" (ext: ''
        "$cursor_bin" --install-extension ${lib.escapeShellArg ext} --force >/dev/null || true
      '') cursorExtensions}
    fi
  '';
}

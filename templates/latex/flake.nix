{
  description = "Academic job materials (CV, statements, letters; latexmk)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # TeX Live comes from the machine flake (research.nix → texliveFull).
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            watchexec
            git
            (python3.withPackages (
              ps: with ps; [
                tomli
              ]
            ))
          ];

          shellHook = ''
            echo "Academic job materials"
            echo "  Config:  config.toml + applications.toml"
            echo "  Sync CV: just sync"
            echo "  Build:   just pdf"
            echo "  Apps:    just app-new … | just app-show <slug> | just status | just ship <slug>"
            echo "  You write; Cursor helps structure/formatting/feedback (AGENTS.md)."
            if ! command -v latexmk >/dev/null 2>&1; then
              echo "  WARN: latexmk not on PATH — enable [research] and rebuild the machine flake."
            fi
          '';
        };
      }
    );
}

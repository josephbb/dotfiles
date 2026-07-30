{
  description = "R + renv + Quarto scratch (nix)";

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
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            R
            quarto
            git
            # Common native deps for tidyverse / renv builds
            gnumake
            pandoc
            libxml2
            openssl
            zlib
            curl
            fontconfig
            freetype
            harfbuzz
            fribidi
            imagemagick
          ];

          shellHook = ''
            echo "R template shell (R=$(R --version | head -1))"
            echo "  First time: R -e \"renv::restore()\"   # or renv::init()"
            echo "  Quarto:     quarto preview analysis.qmd"
            echo "  GUI:        RStudio (Homebrew cask on this machine)"
          '';
        };
      }
    );
}

{
  description = "OpenAlex dataset harvest (nix + uv)";

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
            uv
            git
            stdenv.cc.cc.lib
            zlib
            libffi
            openssl
          ];

          shellHook = ''
            export UV_PYTHON_PREFERENCE=managed
            export LD_LIBRARY_PATH="${
              pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.libffi
                pkgs.openssl
              ]
            }:''${LD_LIBRARY_PATH:-}"
            export DYLD_LIBRARY_PATH="${
              pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.libffi
                pkgs.openssl
              ]
            }:''${DYLD_LIBRARY_PATH:-}"

            if [ ! -d .venv ]; then
              echo "Creating .venv (uv sync)…"
              uv sync
            fi
            # shellcheck disable=SC1091
            source .venv/bin/activate
            echo "OpenAlex template ready. Load creds with: openalex-load"
            echo "  uv run python scripts/fetch.py"
            echo "  uv run python scripts/compile.py"
          '';
        };
      }
    );
}

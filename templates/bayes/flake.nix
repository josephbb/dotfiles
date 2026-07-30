{
  description = "Bayesian analysis with PyMC (nix + uv)";

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
            # Native libs for SciPy / PyTensor / PyMC stack
            stdenv.cc.cc.lib
            pkg-config
            zlib
            libffi
            openssl
            openblas
          ];

          shellHook = ''
            export UV_PYTHON_PREFERENCE=managed
            export LD_LIBRARY_PATH="${
              pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.libffi
                pkgs.openssl
                pkgs.openblas
              ]
            }:''${LD_LIBRARY_PATH:-}"
            export DYLD_LIBRARY_PATH="${
              pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
                pkgs.libffi
                pkgs.openssl
                pkgs.openblas
              ]
            }:''${DYLD_LIBRARY_PATH:-}"

            if [ ! -d .venv ]; then
              echo "Creating .venv (uv sync)…"
              uv sync
            fi
            # shellcheck disable=SC1091
            source .venv/bin/activate
            echo "Ready (python=$(python --version)). Run ./scripts/install_kernel.sh for VS Code."
          '';
        };
      }
    );
}

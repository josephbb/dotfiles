{
  description = "Bayesian analysis with PyMC / NumPyro / CmdStanPy (nix + uv)";

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
        libPath = pkgs.lib.makeLibraryPath (
          [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.libffi
            pkgs.openssl
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.openblas ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
            git
            cmdstan
            graphviz # `dot` for Bambi / PyMC model graphs
            stdenv.cc.cc.lib
            pkg-config
            zlib
            libffi
            openssl
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ openblas ];

          shellHook = ''
            export UV_PYTHON_PREFERENCE=managed
            export CMDSTAN="${pkgs.cmdstan}/opt/cmdstan"
            # macOS wheels link Accelerate; nix OpenBLAS on DYLD_* breaks NumPy.
            unset DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH DYLD_INSERT_LIBRARIES
            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"
            ''}

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

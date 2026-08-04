{
  description = "Joseph's macOS machine config (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      agenix,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "jbakcoleman";

      # One directory under hosts/<name>/ → darwinConfigurations.<name>
      mkDarwin =
        hostName:
        let
          hostPath = ./hosts + "/${hostName}";
          features = builtins.fromTOML (builtins.readFile (hostPath + "/features.toml"));
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit username features; };
          modules = [
            hostPath
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ agenix.homeManagerModules.default ];
              # Back up preexisting dotfiles instead of failing the switch.
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit username features agenix;
              };
              home-manager.users.${username} = import ./home;
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        macbook = mkDarwin "macbook";
        # Add another host: copy hosts/macbook → hosts/<name>, tune features.toml / casks, then:
        #   <name> = mkDarwin "<name>";
      };

      # Project starters: nix flake new -t ~/dotfiles#<name> ~/Projects/...
      templates = {
        scratch = {
          path = ./templates/scratch;
          description = "Light reproducible Python sandbox (blog / quick analysis)";
        };
        bayes = {
          path = ./templates/bayes;
          description = "Python + uv + PyMC / ArviZ Bayesian analysis";
        };
        openalex = {
          path = ./templates/openalex;
          description = "OpenAlex harvest → Parquet datasets under ~/Datasets";
        };
        r = {
          path = ./templates/r;
          description = "R + renv + Quarto stub";
        };
        default = self.templates.scratch;
      };

      # Convenience: nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}

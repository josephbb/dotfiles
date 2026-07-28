{
  description = "Joseph's macOS machine config (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "jbakcoleman";
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          ./hosts/macbook
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up preexisting dotfiles instead of failing the switch.
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit username; };
            home-manager.users.${username} = import ./home;
          }
        ];
      };

      # Project starters: nix flake new -t ~/dotfiles#python ~/Projects/my-analysis
      templates = {
        python = {
          path = ./templates/python;
          description = "Barebones Python analysis (nix + uv + PyMC/pandas/polars)";
        };
        default = self.templates.python;
      };

      # Convenience: nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}

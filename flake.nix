{
  description = "brzrkr - barebones NixOS + Hyprland (Lua) + Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # One base16 scheme themes GTK/cursor/fonts consistently (Omarchy-style)
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spotify client patching (theme + extensions)
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      hostname = "brzrkr";
      username = "pjanderson";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };
        modules = [
          # Custom packages overlay (pkgs.custom.*)
          { nixpkgs.overlays = [ (final: prev: { custom = import ./pkgs { pkgs = prev; }; }) ]; }

          # Disko - declarative partitioning
          inputs.disko.nixosModules.disko
          ./hosts/brzrkr/disko.nix
          ./hosts/brzrkr/hardware-configuration.nix

          # Host + system modules
          ./hosts/brzrkr/default.nix
          ./modules/desktop.nix
          ./modules/nvidia.nix
          ./modules/gaming.nix

          # Theming (stylix + our palette choices)
          inputs.stylix.nixosModules.stylix
          ./modules/theme.nix

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs username; };
              users.${username} = import ./home/default.nix;
            };
          }
        ];
      };

      # Development shell for this flake
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ nil nixpkgs-fmt ];
      };
    };
}

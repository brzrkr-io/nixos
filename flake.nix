{
  description = "erewhon - barebones NixOS + Hyprland (Lua) + Noctalia";

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

    # App-aware key remapping (mac Cmd shortcuts inside GUI apps)
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # Noctalia tracks upstream v5 directly and follows this system's nixpkgs.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # omp (oh-my-pi) coding agent. Deliberately NOT following our nixpkgs:
    # their flake pins rust-overlay + nix-bun versions the build is tested
    # against (nixpkgs only packages omp on master, newer than our pin)
    oh-my-pi.url = "github:can1357/oh-my-pi";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      hostname = "erewhon";
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

          # Disko - declarative partitioning
          inputs.disko.nixosModules.disko
          ./hosts/erewhon/disko.nix
          ./hosts/erewhon/hardware-configuration.nix

          # Host + system modules
          ./hosts/erewhon/default.nix
          ./modules/desktop.nix
          ./modules/nvidia.nix
          ./modules/gaming.nix

          # Theming (stylix + our palette choices)
          inputs.stylix.nixosModules.stylix
          ./modules/theme.nix

          # Mac-style Cmd shortcuts inside GUI apps
          inputs.xremap-flake.nixosModules.default
          ./modules/mac-keys.nix


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

{
  description = "NixOS configuration with flake-parts";

  nixConfig = {
    trusted-substituters = [
      "https://cachix.cachix.org"
      "https://nixpkgs.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    autoaspm = {
      url = "github:notthebee/AutoASPM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, disko, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        # Export overlays for reuse
        overlays = import ./overlays;

        # Define your NixOS configurations here
        nixosConfigurations = {
          adam = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              disko.nixosModules.disko
              ./machines/nixos/adam/configuration.nix
              { nixpkgs.overlays = [ self.overlays.jellyfin-ffmpeg ]; }
            ];
          };
          lilith = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              disko.nixosModules.disko
              ./machines/nixos/lilith/configuration.nix
            ];
          };
        };
      };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here
        # For example, development shells, packages, etc.
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            nixfmt-rfc-style
          ];
        };
      };
    };
}

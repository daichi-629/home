{
  description = "Home Manager configuration of dmtst";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs_unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, home-manager, nixpkgs_unstable
    , sops-nix, ... }:
    let
      overlays = [ rust-overlay.overlays.default ];
      mkHome = { hostName, system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system overlays;
            config = { allowUnfree = true; };
          };

          modules = [
            ./home/common.nix
            (./home/hosts + "/${hostName}.nix")
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            }
          ];
          extraSpecialArgs = {
            pkgs_unstable = import nixpkgs_unstable {
              inherit system;
              config = { allowUnfree = true; };
            };
            inherit sops-nix self;
          };
        };
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      homeConfigurations = {
        "dmtst@IsobeLab-Daichi" = mkHome {
          hostName = "IsobeLab-Daichi";
          system = "x86_64-linux";
          username = "dmtst";
        };
        "daichi@DESKTOP-R3C4CNN" = mkHome {
          hostName = "DESKTOP-R3C4CNN";
          system = "x86_64-linux";
          username = "daichi";
        };
      };
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          updatePins =
            (import ./scripts/update-pin.nix { inherit pkgs self; }).updatePins;
          updateAll = (import ./scripts/update-all.nix {
            inherit pkgs updatePins;
          }).updateAll;
        in {
          update-all = updateAll;
          update-pins = updatePins;
        });
      apps = forAllSystems (system: {
        update-all = {
          type = "app";
          program = "${self.packages.${system}.update-all}/bin/update-all";
        };
        update-pins = {
          type = "app";
          program = "${self.packages.${system}.update-pins}/bin/update-pins";
        };
      });
    };
}

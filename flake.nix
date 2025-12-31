{
  description = "Home Manager configuration of dmtst";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {self, nixpkgs, home-manager, ... }:
    let
      mkHome = { hostName, system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = {allowUnfree = true; };
          };

          modules = [
            ./home/common.nix
            (./home/hosts + "/${hostName}.nix")
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            }
          ];
        };
      systems= ["x86_64-linux"];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      homeConfigurations = {
        "dmtst@IsobeLab-Daichi" = mkHome { hostName = "IsobeLab-Daichi"; system = "x86_64-linux"; username="dmtst"; };
      };
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pythonEnv = pkgs.python3.withPackages (ps: [ ]);
          updatePins = pkgs.writeShellApplication {
            name="update-pins";
            runtimeInputs = [pkgs.git pythonEnv ];
            text = ''
             exec ${pythonEnv}/bin/python ${self}/scripts/update-pins.py "$@" 
            '';
          };
          in
          {
            update-pins= updatePins;
          }
      );
      apps = forAllSystems(system: {
        update-pins = {
          type = "app";
          program = "${self.packages.${system}.update-pins}/bin/update-pins";
        };
      });
    };
}

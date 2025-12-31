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
    { nixpkgs, home-manager, ... }:
    let
      mkHome = { hostName, system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config = {allowUnfree = false; };
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
    in
    {
      homeConfigurations = {
        "dmtst@IsobeLab-Daichi" = mkHome { hostname = "IsobeLab-Daichi"; system = "x86_64-linux"; username="dmtst"; };
      };
    };
}

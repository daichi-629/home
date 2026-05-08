{
  description = "Standalone nixvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib.mkNixvimPackage =
        {
          pkgs,
          lang ? { },
          clipboardProvider ? "auto",
        }:
        nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
          inherit pkgs;
          module = import ./module.nix;
          extraSpecialArgs = {
            inherit clipboardProvider lang;
          };
        };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = self.lib.mkNixvimPackage { inherit pkgs; };
          nvim = self.packages.${system}.default;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          nixvimModule = {
            inherit pkgs;
            module = import ./module.nix;
            extraSpecialArgs = {
              clipboardProvider = "auto";
              lang = { };
            };
          };
        in
        {
          default = nixvim.lib.${system}.check.mkTestDerivationFromNixvimModule nixvimModule;
        }
      );
    };
}

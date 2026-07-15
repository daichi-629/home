{
  description = "Hugging Face Text Embeddings Inference (multilingual-e5-small router) overlay.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "aarch64-darwin" ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          text-embeddings-router = pkgs.callPackage ./package.nix { };
        in
        {
          inherit text-embeddings-router;
          default = text-embeddings-router;
        }
      );

      overlays.default = _final: prev: {
        text-embeddings-router = self.packages.${prev.stdenv.hostPlatform.system}.text-embeddings-router;
      };
    };
}

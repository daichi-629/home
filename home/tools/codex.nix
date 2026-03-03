{ pkgs, config, pkgs_unstable, lib, ... }:

let
  cfg = config.my.tools.codex;
  nodePkgs = pkgs.callPackage ../node2nix { inherit pkgs; };
  nodeDependencies = nodePkgs.nodeDependencies;
  codexPkg = pkgs.writeShellScriptBin "codex" ''
    exec "${nodeDependencies}/bin/codex" "$@"
  '';
in {
  options.my.tools.codex.enable = lib.mkEnableOption "Codex toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [ codexPkg ];
    home.file.".codex/config.yaml".source = ../../dotfiles/.codex/config.toml;
    programs.zsh.initContent = ''
      eval "$(codex completion zsh)"
    '';
  };
}

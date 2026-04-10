{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.lang.ruby;
in
{
  options.my.lang.ruby.enable = lib.mkEnableOption "Ruby language support";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ruby
      solargraph
      rubyPackages.ruby-lsp
      rubyPackages.standard
      rubyPackages.htmlbeautifier
    ];
  };
}

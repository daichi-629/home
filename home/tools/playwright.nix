{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.playwright;
  nodePkgs = pkgs.callPackage ../node2nix { inherit pkgs; };
  nodeDependencies = nodePkgs.nodeDependencies;
  playwrightPkg = pkgs.writeShellScriptBin "playwright-cli" ''
    set -euo pipefail

    if [ $# -gt 0 ] && [ "$1" = "open" ]; then
      has_browser_arg=0
      for arg in "$@"; do
        case "$arg" in
          --browser|--browser=*|-b)
            has_browser_arg=1
            ;;
        esac
      done

      if [ "$has_browser_arg" -eq 0 ]; then
        "${nodeDependencies}/bin/playwright-cli" install-browser --browser=chrome
        exec "${nodeDependencies}/bin/playwright-cli" "$@" --browser=chromium
      fi
    fi

    exec "${nodeDependencies}/bin/playwright-cli" "$@"
  '';
in {
  options.my.tools.playwright.enable =
    lib.mkEnableOption "Playwright CLI toolchain";

  config = lib.mkIf cfg.enable { home.packages = [ playwrightPkg ]; };
}

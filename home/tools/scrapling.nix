{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.scrapling;
  scraplingPkg = pkgs.writeShellScriptBin "scrapling" ''
    set -euo pipefail

    image="''${SCRAPLING_DOCKER_IMAGE:-ghcr.io/d4vinci/scrapling:latest}"
    docker_args=(
      run
      --rm
      -i
      -v "$PWD:/work"
      -w /work
      --entrypoint /app/.venv/bin/scrapling
    )

    if [ -t 0 ] && [ -t 1 ]; then
      docker_args+=(-t)
    fi

    exec ${pkgs.docker-client}/bin/docker "''${docker_args[@]}" "$image" "$@"
  '';
in
{
  options.my.tools.scrapling.enable = lib.mkEnableOption "Scrapling Docker CLI wrapper";

  config = lib.mkIf cfg.enable { home.packages = [ scraplingPkg ]; };
}

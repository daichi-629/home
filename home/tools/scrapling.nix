{ config, pkgs, pkgs_unstable, lib, ... }:

let
  cfg = config.my.tools.scrapling;
  scraplingPkg = pkgs.writeShellScriptBin "scrapling" ''
    set -euo pipefail

    image="''${SCRAPLING_DOCKER_IMAGE:-ghcr.io/d4vinci/scrapling:latest}"
    container_pwd=/work
    pwd_prefix="$PWD/"
    translated_args=()
    bind_args=()
    declared_binds=()

    add_bind() {
      host_path="$1"

      case "$host_path" in
        ""|/)
          return
          ;;
      esac

      mkdir -p "$host_path"

      case " ''${declared_binds[*]} " in
        *" $host_path "*) return ;;
      esac

      declared_binds+=("$host_path")
      bind_args+=(-v "$host_path:$host_path")
    }

    translate_path() {
      path="$1"

      case "$path" in
        "$PWD")
          printf '%s' "$container_pwd"
          ;;
        "$PWD"/*)
          stripped="''${path#"$pwd_prefix"}"
          printf '%s' "$container_pwd/$stripped"
          ;;
        "$HOME")
          printf '%s' "$HOME"
          ;;
        "$HOME"/*)
          printf '%s' "$path"
          ;;
        /*)
          add_bind "''${path%/*}"
          printf '%s' "$path"
          ;;
        *)
          printf '%s' "$path"
          ;;
      esac
    }

    # Scrapling runs inside the container, so host paths need to be rewritten
    # when they point at mounts that are not shared at the same location.
    for arg in "$@"; do
      case "$arg" in
        *=*)
          key="''${arg%%=*}"
          value="''${arg#*=}"
          translated_args+=("$key=$(translate_path "$value")")
          ;;
        /*)
          translated_args+=("$(translate_path "$arg")")
          ;;
        *)
          translated_args+=("$arg")
          ;;
      esac
    done

    docker_args=(
      run
      --rm
      -i
      -v "$PWD:/work"
      -v "$HOME:$HOME"
      --entrypoint /app/.venv/bin/scrapling
    )

    docker_args+=("''${bind_args[@]}")

    docker_args+=(-w /work)

    if [ -t 0 ] && [ -t 1 ]; then
      docker_args+=(-t)
    fi

    exec ${pkgs_unstable.docker-client}/bin/docker "''${docker_args[@]}" "$image" "''${translated_args[@]}"
  '';
in
{
  options.my.tools.scrapling.enable = lib.mkEnableOption "Scrapling Docker CLI wrapper";

  config = lib.mkIf cfg.enable { home.packages = [ scraplingPkg ]; };
}

{ pkgs, updatePins, ... }:
let
in {
  updateAll = pkgs.writeShellScriptBin "update-all" ''
    set -euo pipefail

    repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    cd "$repo_root"

    ${updatePins}/bin/update-pins
    ${pkgs.nix}/bin/nix flake update

    if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
      ${pkgs.git}/bin/git add -A
      if [ "$#" -gt 0 ]; then
        commit_msg="$*"
      else
        printf "Commit message: "
        read -r commit_msg
      fi
      if [ -n "$commit_msg" ]; then
        ${pkgs.git}/bin/git commit -m "$commit_msg"
        ${pkgs.git}/bin/git push
      else
        echo "Commit message empty; skipping commit/push." >&2
      fi
    else
      echo "No changes to commit."
    fi

    hm_user="''${USER:-$(${pkgs.coreutils}/bin/id -un)}"
    hm_host="''${HOSTNAME:-$(${pkgs.coreutils}/bin/hostname)}"
    ${pkgs.home-manager}/bin/home-manager switch --flake ".#''${hm_user}@''${hm_host}"
  '';
}

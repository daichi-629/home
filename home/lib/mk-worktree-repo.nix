# ./lib/mk-worktree-repo.nix
{ lib, pkgs }:

{ pinKey, pinsFile, # 例: ../../pins/repos.json（呼び出し側で渡す）
name ? pinKey, homeDir, # 例: config.home.homeDirectory（呼び出し側で渡す）
workdirBase ? "${homeDir}/src", workdirName ? name
, before ? [ "linkGeneration" ] # clone をリンクより先に走らせる
}:

let
  pins = builtins.fromJSON (builtins.readFile pinsFile);

  repo = if builtins.hasAttr pinKey pins then
    builtins.getAttr pinKey pins
  else
    throw "pinsFile に ${pinKey} がありません";

  url = if repo ? url then repo.url else throw "${pinKey}: url が pins にありません";
  rev = if repo ? rev then repo.rev else throw "${pinKey}: rev が pins にありません";

  workdir = "${workdirBase}/${workdirName}";
  git = lib.getExe pkgs.git;
  ssh = lib.getExe pkgs.openssh;
  activationName = "clone_"
    + (lib.replaceStrings [ "/" " " "-" "." ] [ "_" "_" "_" "_" ] name);

  activationScript = lib.hm.dag.entryBefore before ''
    set -euo pipefail

    # 非対話実行なので、鍵確認やパスフレーズ入力を要求されると失敗します
    export GIT_SSH_COMMAND="${ssh} -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$HOME/.ssh/known_hosts"

    if [ ! -d "${workdir}/.git" ]; then
      mkdir -p "$(dirname "${workdir}")"
      ${git} clone ${url} "${workdir}"
    fi

    cd "${workdir}"
    ${git} fetch --all --tags --prune

    if ${git} diff --quiet && ${git} diff --cached --quiet; then
      ${git} checkout --detach ${rev}
    else
      echo "${name}: ローカル変更があるため checkout をスキップしました"
    fi
  '';
in {
  inherit name workdir;
  activation = { ${activationName} = activationScript; };

}


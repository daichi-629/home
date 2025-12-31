# home/lib/mk-worktree-repo-module.nix
{ lib, pkgs }:

{
  pinKey,                              # pins/repos.json 内のキー名
  name ? pinKey,                       # activation名やデフォルトdir名に使う
  pinsFile ? ../../pins/repos.json,    # pinsファイルのパス（このファイルから見た相対）
  workdir ? null,                      # 明示指定したい場合
  workdirBase ? null,                  # nullなら ~/src
  workdirName ? name,                  # workdirを組み立てるときのディレクトリ名
  after ? [ "writeBoundary" ],         # activation DAG
  xdgConfigLinks ? {},                 # { "zsh/lang/node.zsh" = "zsh/lang/node.zsh"; ... }
  homeFileLinks ? {}                   # { ".zshrc" = "zsh/.zshrc"; ... }
}:

{ config, ... }:

let
  pins = builtins.fromJSON (builtins.readFile pinsFile);

  repo =
    if builtins.hasAttr pinKey pins
    then builtins.getAttr pinKey pins
    else throw "pinsFile に ${pinKey} がありません";

  url =
    if repo ? url then repo.url else throw "${pinKey}: url が pins にありません";
  rev =
    if repo ? rev then repo.rev else throw "${pinKey}: rev が pins にありません";

  base = if workdirBase != null then workdirBase else "${config.home.homeDirectory}/src";
  wd = if workdir != null then workdir else "${base}/${workdirName}";

  git = lib.getExe pkgs.git;

  activationName =
    "clone_" + (lib.replaceStrings [ "/" " " "-" "." ] [ "_" "_" "_" "_" ] name);

  mkXdgLink = target: src: {
    name = target;
    value.source = config.lib.file.mkOutOfStoreSymlink "${wd}/${src}";
  };

  mkHomeLink = target: src: {
    name = target;
    value.source = config.lib.file.mkOutOfStoreSymlink "${wd}/${src}";
  };
in
{
  home.activation.${activationName} = lib.hm.dag.entryAfter after ''
    set -euo pipefail

    if [ ! -d "${wd}/.git" ]; then
      mkdir -p "$(dirname "${wd}")"
      ${git} clone ${url} "${wd}"
    fi

    cd "${wd}"
    ${git} fetch --all --tags --prune

    if ${git} diff --quiet && ${git} diff --cached --quiet; then
      ${git} checkout --detach ${rev}
    else
      echo "${name}: ローカル変更があるため checkout をスキップしました"
    fi
  '';

  xdg.configFile = lib.listToAttrs (lib.mapAttrsToList mkXdgLink xdgConfigLinks);
  home.file      = lib.listToAttrs (lib.mapAttrsToList mkHomeLink homeFileLinks);
}


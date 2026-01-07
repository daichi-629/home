# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ~/.zshrc.d ディレクトリが存在する場合のみ実行
if [[ -d ~/.zshrc.d ]]; then
  # ~/.zshrc.d 内のファイルを再帰的に検索し、ループ処理
  # (N) はglobの結果がなくてもエラーにしないためのオプション
  # (.) は通常ファイルのみを対象にするためのglob qualifier
  for file in ~/.zshrc.d/**/*(.N); do
    # ファイルに読み取り権限がある場合のみ source する
    if [[ -r "$file" ]]; then
      source "$file"
    fi
  done
  # 変数fileをクリーンアップ
  unset file
fi
# Set up fzf key bindings and fuzzy completion
eval "$(zoxide init zsh)"

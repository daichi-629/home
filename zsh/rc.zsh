# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

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
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

export TMUX_TMPDIR=/tmp/

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end



export PATH=$PATH:$HOME/.local/bin
export EDITOR="nvim"

alias ls="eza --icons=always --classify=always --hyperlink"
alias npm="pnpm"
alias orgnpm="npm"

export PATH="$PATH:/usr/local/texlive/2025/bin/x86_64-linux"
# Set up fzf key bindings and fuzzy completion


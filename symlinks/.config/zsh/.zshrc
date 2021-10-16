# https://nixos.wiki/wiki/Nix_Installation_Guide
# source /run/current-system/sw/etc/profile.d/nix.sh

autoload -Uz compinit promptinit # bashcompinit
compinit -u
promptinit
# bashcompinit

zstyle ':completion:*' menu  select
prompt adam2

set -o histignore{space,alldups}

bindkey -v
zle-line-init() { zle -K vicmd; }
zle -N zle-line-init

function expand-alias() {
    zle _expand_alias
    zle self-insert
}
zle -N expand-alias
bindkey -M main ' ' expand-alias

# https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zsh/.zshrc
export KEYTIMEOUT=1

zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select

autoload -z edit-command-line
zle -N edit-command-line
bindkey -M main '^x^e' edit-command-line

# misc
# nix shell nixpkgs#vis -c \\
#   vis +"cd $HOME/vc"
# pax -rwlq scimax ~/.emacs.d

# fpath=(~/.local/share/zsh $fpath) compinit

# sftp -P 2207
# rsync -uzrqPlt
# rsync -auzLP

# Aliases

alias n=nix \
      g=git \
      x=exec \
      s=sway \
      kek=kak

# alias l=' ls -AGFS' \
alias l=' ls -AF' \
      b=' ddcutil setvcp 12' \
      t=' exec tmux' \
      k=' exec tmux new kak' \
      lo=' ls -AFRo' \
      te=' , eza -T' \
      xs=' exec $SHELL' \
      gs=' git -C ~/.dotfiles me git ss -bs' \
      nd=' nix develop' \
      nt=' nixos-rebuild test'

unset EDITOR PAGER NIX_PATH
source ~/.config/zsh/vi-increment/vi-increment.zsh
export RIDE_JS=~/.config/Ride-4.5/vim.js

# . /run/current-system/sw/etc/profile.d/nix.sh # https://wiki.nixos.org/wiki/Nix_Installation_Guide
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
export KEYTIMEOUT=1 # https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zsh/.zshrc
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac }
zle -N zle-keymap-select
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M main '^x^e' edit-command-line
unset PAGER NIX_PATH NIXPKGS_CONFIG
export EDITOR=kak RIDE_JS=~/.config/Ride/vim.js FLAKE=$(readlink -f ~/.dotfiles)
alias n=nix \
      g=git \
      k=kek \
      x=exec \
      t=tmux \
      b=brightnessctl \
      sw=sway \
      nr=nixos-rebuild \
      kek=kak \
      l=' ls -AF' \
      d=' ddcutil setvcp 12' \
      te=' , eza -Ta' \
      xs=' exec $SHELL' \
      nd=' nix develop' \
      ns=' nix shell nixpkgs#' \
      st=' swaymsg output eDP-1 toggle' \
      rs=' rsync -auzL --no-i-r --info=progress2' \
      dy=' CONFIGFILE= rlwrap -a mapl -b -s'
# pax -rwlq scimax ~/.emacs.d
# DynamicForward 1080
# LocalForward 4502 *:4502
# ServerAliveInterval 15
# Compression yes
# fpath=(~/.local/state/nix/profile/share/zsh/vendor-completions $fpath) compinit
. ~/.config/zsh/vi-increment/vi-increment.zsh

# . /run/current-system/sw/etc/profile.d/nix.sh
# https://wiki.nixos.org/wiki/Nix_Installation_Guide
zmodload zsh/complist; autoload -Uz compinit; compinit -u
zstyle ':completion:*' menu  select; _comp_options+=(globdots)
setopt histignorespace histignorealldups autopushd pushdignoredups
PROMPT=$'%m:%~\n%S%#%s '
bindkey -v
zle-line-init() { zle -K vicmd; }; zle -N zle-line-init
function expand-alias() {
    zle _expand_alias
    zle self-insert
}; zle -N expand-alias; bindkey -M main ' ' expand-alias
# https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zsh/.zshrc
export KEYTIMEOUT=1
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
autoload -z edit-command-line; zle -N edit-command-line
bindkey -M main '^x^e' edit-command-line
unset PAGER NIX_PATH NIXPKGS_CONFIG
export EDITOR=kak \
       RIDE_JS=~/.config/Ride/vim.js \
       NH_FLAKE=$(readlink -f ~/.dotfiles) \
       RLWRAP_HOME=~/.config/rlwrap
alias n=nix \
      g=git \
      t=tmux \
      kk=kek \
      sw=sway \
      nr=nixos-rebuild \
      kek=kak \
      l=' ls -AF' \
      s=' echo $SHLVL' \
      b=' brightnessctl -sm s' \
      xs=' exec $SHELL' \
      nd=' nix develop' \
      st=' swaymsg output eDP-1 toggle' \
      rl=' rlwrap -crm -D 2' \
      dy=' CONFIGFILE= rlwrap -acrm -D 2 mapl -b -s' \
# rsync -auzL --no-i-r --info=progress2
# ddcutil setvcp 12

# pax -rwlq scimax ~/.emacs.d
# DynamicForward 1080
# LocalForward 4502 *:4502
# ServerAliveInterval 15
# Compression yes
# fpath=(~/.local/state/nix/profile/share/zsh/vendor-completions $fpath) compinit

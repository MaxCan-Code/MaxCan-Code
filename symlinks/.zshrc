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

_hl_paths() { # underline existing paths and words with escaped/quoted spaces
  (( KEYS_QUEUED_COUNT )) && return # pasting: skip until input settles
  local w p r s i=1
  region_highlight=( "${(@)region_highlight:#*memo=hl_paths*}" ) # keep others' entries
  for w in ${(z)BUFFER}; do
    s=${BUFFER[(ieb:i:)$w]} # e: exact match, not pattern
    (( s > $#BUFFER )) && continue # newline -> synthetic ';' token
    (( i = s + $#w ))
    r=${w//\\?/}; r=${(S)r//\'*\'/} # drop \x and '...': those are literal
    [[ $r == *\$* || ${(S)r//\"*\"/} == *[\*\?\[]* ]] && continue # live $/glob
    p=${(Q)w}; p=${p/#\~/$HOME}
    if [[ -e $p || $p == *[[:space:]]* ]] ||
       { (( i > $#BUFFER )) && [[ -n $p ]] && () { (( $# )) } $p*(N[1]) } # last word: path prefix
    then region_highlight+=("$((s-1)) $((s-1+$#w)) underline, memo=hl_paths"); fi
  done
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _hl_paths

unalias run-help; autoload -Uz ${^fpath}/run-help-*(N:t)
zshaddhistory() { [[ $1 != 'run-help '* ]] }
autoload -Uz +X run-help
functions[run-help-orig]=$functions[run-help]
run-help() {
  local HELPDIR=/nonexistent pat
  case $1 in
    ''|-*) ;;
    *) pat="less -p '^\h*${1} '" ;;
  esac
  MANPAGER=${pat:-less} MANWIDTH=${COLUMNS:-80} run-help-orig "$@"
}
bindkey -M vicmd 'K' run-help
bindkey -M viins '^K' run-help
function command_not_found_handler () {
    comma --ask "$@"
    return $?
}
export EDITOR=kak \
       LESS=-RFXi \
       RIDE_JS=~/.config/Ride/vim.js \
       NH_FLAKE=$(readlink -f ~/.dotfiles) \
       RLWRAP_HOME=~/.config/rlwrap
alias n=nix \
      g=git \
      s=ssh \
      y=yazi \
      k=kek \
      rm=gomi \
      nr=nixos-rebuild \
      kek=kak \
      l=' ls -AF' \
      b=' brightnessctl -sm s' \
      xs=' exec $SHELL' \
      ss=' echo $SHLVL' \
      nd=' nix develop' \
      rl=' rlwrap -crm -D 2' \
      ⍺=' rlwrap -a -crm -D 2 mapl -b -s'
# rsync -auzL --no-i-r --info=progress2
# ddcutil setvcp 12
# print -l $fpath

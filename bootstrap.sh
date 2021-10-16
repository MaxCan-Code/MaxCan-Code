#!/bin/sh

# gimme free sudo
# %admin		ALL = (ALL) NOPASSWD: ALL
# %admin		ALL = (ALL) ALL, NOPASSWD: /usr/sbin/visudo, /usr/sbin/vipw

zero apply-defaults
# https://stackoverflow.com/a/56137655
defaults delete com.apple.dock persistent-apps
defaults delete com.apple.dock persistent-others
killall Dock Finder

echo start https://github.com/StevenBlack/hosts#macos
cd /etc
sudo curl -LO http://sbc.io/hosts/alternates/fakenews-gambling-porn-social/hosts
sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder
cd
echo end https://github.com/StevenBlack/hosts#macos

rm -r ~/.{emacs.d,vim,qutebrowser}
zero apply-symlinks

echo is nix on?
read

pkgs=nixpkgs/nixpkgs-unstable
nix run ~/.dotfiles -- switch -n --flake ~/.dotfiles

q=~/.qutebrowser/config
nix shell $pkgs#hy -c hy2py $q.hy | tail -n +2 -- > $q.py

v=~/.config/vis
nix run $pkgs#fennel -- -c $v/visrc.fnl > $v/visrc.lua
nix run $pkgs#fennel -- -c $v/themes/nu.fnl > $v/themes/nu.lua
# nix shell $pkgs#{hy,fennel} -c \

echo start piu
chmod +x ~/.config/piu/piu
sudo ln -svn ~/.config/piu/piu /usr/local/bin

piu i -q shortcat amethyst
open /Applications/{Shortcat,Amethyst}.app

piu i -q honer joshjon-nocturnal
# https://grain-lang.org/docs/getting_grain#MacOS-x64---Homebrew
brew install --no-quarantine qutebrowser

open /Applications/{Honer,Nocturnal,qutebrowser}.app

piu i -q --cask jasper

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

if [ ! -f ~/bin/micromamba ]; then
    curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xvj bin/micromamba
    mv bin ~
fi
mkdir ~/micromamba
~/bin/micromamba install -yf ~/.mambarc.yml
~/micromamba/bin/luarocks --local install fennel

rm -r ~/.{emacs.d,vim,qutebrowser}
mkdir ~/.qutebrowser
touch ~/.qutebrowser/q # block bkmk symlinks

zero apply-symlinks

q=~/.qutebrowser/config
~/micromamba/bin/hy2py $q.hy | tail -n +2 -- > $q.py

v=~/.config/vis
~/.luarocks/bin/fennel -c $v/visrc.fnl > $v/visrc.lua
~/.luarocks/bin/fennel -c $v/themes/nu.fnl > $v/themes/nu.lua

~/micromamba/bin/cargo install -q watchexec-cli ripgrep broot gitui

echo start piu
chmod +x ~/.config/piu/piu
sudo ln -svn ~/.config/piu/piu /usr/local/bin

piu i -q neovim github shortcat amethyst
github ~/.dotfiles
open /Applications/{Shortcat,Amethyst}.app

piu i -q honer joshjon-nocturnal qutebrowser
open /Applications/{Honer,Nocturnal,qutebrowser}.app

piu i -q --HEAD vis kakoune

# cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask/Casks
# https://www.zotero.org/support/dev_builds
# curl -LO https://github.com/alanjferguson/homebrew-cask-versions/raw/adding-zotero-beta/Casks/zotero-beta.rb
# cd
# piu i -q --cask docker julia zotero-beta

# brew tap d12frosted/emacs-plus
piu i -q d12frosted/emacs-plus/emacs-plus@28 # --with-{no-titlebar,xwidgets,native-comp}
piu i -q enchant

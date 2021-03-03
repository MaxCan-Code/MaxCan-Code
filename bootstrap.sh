#!/bin/sh

# gimme free sudo
# %admin		ALL = (ALL) NOPASSWD: ALL
# %admin		ALL = (ALL) ALL, NOPASSWD: /usr/sbin/visudo, /usr/sbin/vipw

zero apply-defaults
# https://stackoverflow.com/a/56137655
defaults delete com.apple.dock persistent-apps
defaults delete com.apple.dock persistent-others
killall Dock Finder

# https://github.com/StevenBlack/hosts#macos
cd /etc
sudo curl -LO http://sbc.io/hosts/alternates/fakenews-gambling-porn-social/hosts
sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder
cd

if [ ! -f ~/bin/micromamba ]; then
    curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xvj bin/micromamba
    mv bin ~
fi
mkdir ~/micromamba
~/bin/micromamba install -yf ~/.mambarc.yml
~/micromamba/bin/hy2py ~/.qutebrowser/config.hy > ~/.qutebrowser/config.py
~/micromamba/bin/luarocks --local install fennel

rm -r ~/{.emacs.d,.vim}
mkdir ~/.qutebrowser && touch ~/.qutebrowser/q # block bkmk symlinks
zero apply-symlinks

v=~/.config/vis
~/.luarocks/bin/fennel --compile $v/visrc.fnl > $v/visrc.lua
~/.luarocks/bin/fennel --compile $v/themes/nu.fnl > $v/themes/nu.lua

~/micromamba/bin/cargo install -q watchexec-cli ripgrep broot gitui

chmod +x ~/.config/piu/piu
sudo ln -sv ~/.config/piu/piu /usr/local/bin

piu i -q neovim github shortcat
piu i -q amethyst honer joshjon-nocturnal qutebrowser

github ~/.dotfiles
open /Applications/{Shortcat,Amethyst,Honer,Nocturnal,qutebrowser}.app

piu i -q --HEAD vis kakoune

# brew tap d12frosted/emacs-plus
piu i -q d12frosted/emacs-plus/emacs-plus@28 # --with-{no-titlebar,xwidgets,native-comp}
piu i -q enchant

cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask/Casks
# https://www.zotero.org/support/dev_builds
curl -LO https://github.com/alanjferguson/homebrew-cask-versions/raw/adding-zotero-beta/Casks/zotero-beta.rb
# piu i -q --cask docker julia zotero-beta

# relative ln -s broken, need to cd
# cd ~/.config/chemacs/scimax
# rm -r user
# ln -sfFv ../scimax-user user
# git restore user

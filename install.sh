#!/bin/sh

# doas badblocks -wso badblocks-sda.txt /dev/sda
doas mkfs.ext4 -cc -L nixos /dev/sda2
doas mkfs.fat -F 32 -cc -n boot /dev/sda1   # (for UEFI systems only)
doas mount /dev/disk/by-label/nixos /mnt
doas mkdir -p /mnt/boot			    # (for UEFI systems only)
doas mount /dev/disk/by-label/EFI /mnt/boot # (for UEFI systems only)
# nixos-generate-config --root /mnt

mkdir -p ~/vc/projects
cd ~/vc/projects
git clone --{remote,shallow,recurse}-submodules \
  https://github.com/MaxCan-Code/MaxCan-Code

ln -srv ~/{vc/projects/MaxCan-Code,.dotfiles}
nixos-generate-config --root /mnt --dir ~/.dotfiles

echo rm -r ~/.{vim,config/nvim}
echo , stow -t ~ -d ~/.dotfiles symlinks
echo rm ~/.config/sway

doas nixos-install --flake ~/$(readlink ~/.dotfiles)#nixos
doas nixos-enter -c 'su - user -c "tmux a"' # clone, comma.sh: stow

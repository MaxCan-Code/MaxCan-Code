# https://wiki.gentoo.org/wiki/Ext4/badblocks
# doas badblocks -s -w -b $(blockdev --getbsz /dev/<device>) /dev/<device> -c (1G*2^10+7)*1-1%4 -o bb.txt
doas mkfs.ext4 -cc -L nixos /dev/sda2
doas mkfs.fat -F 32 -cc -n boot /dev/sda1   # (for UEFI systems only)
doas mount /dev/disk/by-label/nixos /mnt
doas mkdir -p /mnt/boot			    # (for UEFI systems only)
doas mount /dev/disk/by-label/EFI /mnt/boot # (for UEFI systems only)
# nixos-generate-config --root /mnt

mkdir ~/p && cd ~/p
git clone --{remote,shallow,recurse}-submodules \
  https://github.com/MaxCan-Code/MaxCan-Code

ln -srv ~/{p/MaxCan-Code,.dotfiles}
nixos-generate-config --root /mnt --dir ~/.dotfiles

echo rm -r ~/.vim ~/.config/{nvim,sway}
echo , stow -t ~ -d ~/.dotfiles symlinks

ln -srv ~/.dotfiles/flake.nix /etc/nixos
doas nixos-install --flake ~/$(readlink ~/.dotfiles)#nixos
doas nixos-enter -c 'su - user -c "tmux a"' # clone, comma.sh: stow

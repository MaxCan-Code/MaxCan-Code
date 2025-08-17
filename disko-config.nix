{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };
  swapDevices = [];
  # disko.devices.disk.main = {
  #   device = "/dev/disk/by-id/ata-APPLE_SSD_SM0128G_S2XUNY0JC92268";
  #   type = "disk";
  #   content = {
  #     type = "gpt";
  #     partitions = {
  #       ESP = {
  #         label = "ESP";
  #         size = "512M";
  #         type = "EF00";
  #         content = {
  #           type = "filesystem";
  #           format = "vfat";
  #           mountpoint = "/boot";
  #           mountOptions = ["umask=0077"];
  #         };
  #       };
  #       root = {
  #         label = "root";
  #         size = "100%";
  #         content = {
  #           type = "filesystem";
  #           format = "ext4";
  #           mountpoint = "/";
  #         };
  #       };
  #     };
  #   };
  # };
}

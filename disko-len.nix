{
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/ata-CT240BX500SSD1_2405E8943C7C";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          label = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          label = "swap";
          size = "40G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true; # resume from hiberation from this device
          };
        };
      };
    };
  };
}

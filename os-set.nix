{
  nix = {
    channel.enable = false;
    settings = {
      extra-experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "auto-allocate-uids"
        "cgroups"
        "git-hashing"
        "blake3-hashes"
        "pipe-operators"
      ];
      keep-outputs = true;
      auto-allocate-uids = true;
      use-cgroups = true;
      use-xdg-base-directories = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      lint-url-literals = "fatal";
      lint-short-path-literals = "fatal";
      lint-absolute-path-literals = "warn";
      warn-large-path-threshold = 100 * 1024 * 1024;
      # min-free = 1024 * 1024 * 1024;
      # max-free = 1024 * 1024 * 1024;
    };
  };
  powerManagement.powertop.enable = true;
  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  networking = {
    networkmanager.enable = true;
    stevenblack.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # wiremix
    alsa.enable = true;
  };
  hardware = {
    enableAllFirmware = true;
    i2c.enable = true;
    # bluetooth.enable = true;
  };
  environment = {
    localBinInPath = true;
    defaultPackages = [ ];
  };
  services = {
    auto-cpufreq.enable = true;
    # autosuspend.enable = true;
    thermald.enable = true;
    openssh = {
      # enable = true;
      ports = [ 2223 ];
      startWhenNeeded = true;
    };
    samba = {
      enable = true;
      usershares.enable = true;
      openFirewall = true;
    };
    # create_ap = {
    #   enable = true;
    #   settings = {
    #     INTERNET_IFACE = "enu1u4";
    #     PASSPHRASE = "12345678";
    #     SSID = "My Wifi Hotspot";
    #     WIFI_IFACE = "wlan0";
    #   };
    # };
    logind.settings.Login.HandleLidSwitch = "ignore";
    # udisks2.enable = true;
    # keyd.enable = true;
    # envfs.enable = true;
  };
  programs = {
    nano.enable = false;
    zsh.enable = true;
    git.enable = true;
    nix-ld.enable = true;
    sway.enable = true;
    # font=monospace:size=12
    # dpi-aware=yes
    # [colors]
    # alpha=0.8
    wshowkeys.enable = true;
    fuse.enable = true;
  };
  security.sudo.enable = false;
}

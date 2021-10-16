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
        "fetch-closure"
        "dynamic-derivations"
        "no-url-literals"
      ];
      auto-allocate-uids = true;
      use-cgroups = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      min-free = 1024 * 1024 * 1024;
      max-free = 1024 * 1024 * 1024;
    };
  };
  powerManagement.powertop.enable = true;
  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelParams = [ "acpi_backlight=native" ];
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    stevenblack.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # wpctl set-default (hdmi)
    alsa.enable = true;
  };
  hardware = {
    enableAllFirmware = true;
    i2c.enable = true;
    # bluetooth.enable = true;
    # facetimehd = {
    #   enable = true;
    #   withCalibration = true;
    # };
  };
  environment.localBinInPath = true;
  services = {
    auto-cpufreq.enable = true;
    thermald.enable = true;
    openssh = {
      enable = true;
      ports = [ 2223 ];
      startWhenNeeded = true;
    };
    logind.lidSwitch = "ignore";
    # guix.enable = true;
    # udisks2.enable = true;
    # keyd.enable = true;
    kanata = {
      # enable = true;
      keyboards.default = {
        devices = [ ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc caps)
          (deflayer default @cap)
          (defalias ;; cap (tap-hold 100 100 lctl lctl)
                    cap (one-shot 100 lctl))
        '';
      };
    };
  };
  programs = {
    nano.enable = false;
    zsh.enable = true;
    git.enable = true;
    light.enable = true;
    nix-ld.enable = true;
    sway.enable = true;
    # font=monospace:size=12
    # dpi-aware=yes
    # [colors]
    # alpha=0.9
    wshowkeys.enable = true;
  };
  security = {
    sudo.enable = false;
    polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if ( subject.isInGroup("wheel") &&
             action.lookup("program") == "/run/current-system/sw/bin/nixos-rebuild" )
        { return polkit.Result.YES; } });
    '';
  };
}

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
      use-xdg-base-directories = true;
      trusted-users = ["root" "@wheel"];
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
    defaultPackages = [];
  };
  services = {
    auto-cpufreq.enable = true;
    thermald.enable = true;
    openssh = {
      enable = true;
      ports = [2223];
      startWhenNeeded = true;
    };
    samba = {
      # enable = true;
      usershares.enable = true;
      openFirewall = true;
      settings = {
        public = {
          path = "/home/user/Downloads/public";
          writable = "yes";
          "vfs objects" = "catia fruit streams_xattr";
          public = "yes";
        };
      };
    };
    logind.settings.Login.HandleLidSwitch = "ignore";
    # udisks2.enable = true;
    # keyd.enable = true;
    kanata = {
      # enable = true;
      keyboards.default = {
        devices = [];
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
    nix-ld.enable = true;
    sway.enable = true;
    # font=monospace:size=12
    # dpi-aware=yes
    # [colors]
    # alpha=0.8
    wshowkeys.enable = true;
    appgate-sdp.enable = true;
  };
  security = {
    sudo.enable = false;
    # doas.extraConfig = "permit nopass ${main-user} cmd nixos-rebuild";
    polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if ( subject.isInGroup("wheel") &&
             action.lookup("program") == "/run/current-system/sw/bin/nixos-rebuild" )
        { return polkit.Result.YES; } });
    '';
  };
}

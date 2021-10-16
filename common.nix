/*
Edit this configuration file to define what should be installed on
your system.  Help is available in the configuration.nix(5) man page
and in the NixOS manual (accessible by running ‘nixos-help’).
*/
{
  config,
  pkgs,
  ...
}: let
  main-user = "user";
in {
  nix.settings = {
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
    trusted-users = ["root" "@wheel"];
  };

  imports = [./hardware-configuration.nix];
  powerManagement.powertop.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelParams = ["acpi_backlight=native"];

  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    hostFiles = [(pkgs.stevenblack-blocklist + /hosts)];
  };

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # wpctl set-default (hdmi)
    alsa.enable = true;
  };

  hardware = {
    enableAllFirmware = true;
    i2c.enable = true;
    # facetimehd = {
    #   enable = true;
    #   withCalibration = true;
    # };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.${main-user} = {
      isNormalUser = true;
      extraGroups = ["wheel" "video"]; # Enable `sudo` and `light` for the user.
    };
  };

  environment.localBinInPath = true;

  services = {
    getty.autologinUser = main-user;
    auto-cpufreq.enable = true;
    thermald.enable = true;
    openssh = {
      enable = true;
      startWhenNeeded = true;
    };
    # guix.enable = true;
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
    interception-tools = {
      enable = true;
      plugins = [pkgs.interception-tools-plugins.dual-function-keys];
      udevmonConfig = let
        it-bin = pkgs.interception-tools + /bin;
        dual-function-keys = pkgs.interception-tools-plugins.dual-function-keys + /bin/dual-function-keys;
        mac = ".*Apple Internal Keyboard.*";
        matt = ".*Keyboard";
      in ''
        - JOB: |
            ${it-bin}/intercept -g $DEVNODE | ${dual-function-keys} -c \
              ${./symlinks/.config/interception-tools/mac.yaml} |  ${it-bin}/uinput -d $DEVNODE
          DEVICE:
            NAME: ${mac}
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, ]
        - JOB: |
            ${it-bin}/intercept -g $DEVNODE | ${dual-function-keys} -c \
              ${./symlinks/.config/interception-tools/matt.yaml} |  ${it-bin}/uinput -d $DEVNODE
          DEVICE:
            NAME: ${matt}
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_LEFTCTRL, KEY_LEFTALT, KEY_LEFTMETA, KEY_RIGHTALT, KEY_RIGHTMETA, KEY_RIGHTCTRL, ]
      '';
    };
  };

  programs = {
    nano.enable = false;
    zsh.enable = true;
    git.enable = true;
    light.enable = true;
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    sway.enable = true;
    # font=monospace:size=12
    # dpi-aware=yes
    # [colors]
    # alpha=0.9
    wshowkeys.enable = true;
  };

  security = {
    sudo.enable = false;
    doas.extraConfig = "permit nopass ${main-user} cmd nixos-rebuild";
    polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if ( subject.isInGroup("wheel") &&
             action.lookup("program") == "/run/current-system/sw/bin/nixos-rebuild" )
        { return polkit.Result.YES; } });
    '';
  };
}

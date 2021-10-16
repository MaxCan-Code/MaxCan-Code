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
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.${main-user} = {
      isNormalUser = true;
      extraGroups = ["wheel" "video"]; # Enable `sudo` and `light` for the user.
    };
  };
  services = {
    getty.autologinUser = main-user;
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
  security.doas.extraConfig = "permit nopass ${main-user} cmd nixos-rebuild";
}

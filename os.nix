/*
Edit this configuration file to define what should be installed on
your system.  Help is available in the configuration.nix(5) man page
and in the NixOS manual (accessible by running ‘nixos-help’).
*/
inputs @ {pkgs, ...}: let
  main-user = "user";
in {
  # imports = [ "${inputs.modulesPath}/profiles/perlless.nix" ];
  # system.forbiddenDependenciesRegexes = inputs.lib.mkForce [ ]; # perl
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.${main-user} = {
      isNormalUser = true;
      extraGroups = ["wheel" "video" "i2c" "networkmanager"];
    };
  };
  services = {
    getty.autologinUser = main-user;
    interception-tools = {
      enable = true;
      plugins = [pkgs.interception-tools-plugins.dual-function-keys];
      udevmonConfig = let
        it = pkgs.interception-tools + /bin;
        itc = ./symlinks/.config/interception-tools;
        dfk = pkgs.interception-tools-plugins.dual-function-keys + /bin/dual-function-keys;
      in ''
        - JOB: |
            ${it}/intercept -g $DEVNODE | ${dfk} -c ${itc + /caps2ctrl-esc.yaml} |  ${it}/uinput -d $DEVNODE
          DEVICE:
            NAME: .*Apple Internal Keyboard.*
            EVENTS:
              EV_KEY: [[KEY_CAPSLOCK, KEY_ESC]]
        - JOB: |
            ${it}/intercept -g $DEVNODE | ${dfk} -c ${itc + /matt.yaml} |  ${it}/uinput -d $DEVNODE
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_LEFTCTRL, KEY_LEFTALT, KEY_LEFTMETA, KEY_RIGHTALT, KEY_RIGHTMETA, KEY_RIGHTCTRL]
      '';
    };
  };
  security.doas.extraConfig = "permit nopass ${main-user} cmd nixos-rebuild";
}

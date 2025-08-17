/*
Edit this configuration file to define what should be installed on
your system.  Help is available in the configuration.nix(5) man page
and in the NixOS manual (accessible by running ‘nixos-help’).
*/
main-user: inputs @ {pkgs, ...}: {
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
  networking.networkmanager.plugins = [pkgs.networkmanager-openconnect];
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
            ${it}/intercept -g $DEVNODE | ${dfk} -c ${itc + /apple.yaml} |  ${it}/uinput -d $DEVNODE
          DEVICE:
            NAME: .*pple.*eyboard.*
            EVENTS:
              EV_KEY: [KEY_LEFTCTRL, KEY_SPACE, [KEY_CAPSLOCK, KEY_ESC]]
            LINK: .*-event-kbd
        - JOB: |
            ${it}/intercept -g $DEVNODE | ${dfk} -c ${itc + /kb.yaml} |  ${it}/uinput -d $DEVNODE
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_SPACE,     [KEY_CAPSLOCK, KEY_ESC],
                        KEY_LEFTCTRL,  [KEY_LEFTALT,  KEY_LEFTMETA],
                       KEY_RIGHTCTRL, [KEY_RIGHTALT, KEY_RIGHTMETA]]
            LINK: .*-event-kbd
      '';
    };
  };
}

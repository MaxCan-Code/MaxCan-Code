{
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixos-apple-silicon.cachix.org"
      "https://cache.numtide.com"
      "https://cache.lix.systems"
      "https://chaotic-nyx.cachix.org"
      "https://watersucks.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
      "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ride = {
      url = "github:Dyalog/ride";
      flake = false;
    };
    kakoune = {
      url = "github:krobelus/kakoune/jj";
      flake = false;
    };
    ngn-k = {
      url = "git+https://codeberg.org/growler/k";
      flake = false;
    };
    # nixos-wsl.url = "github:nix-community/NixOS-WSL";
    disko.url = "github:nix-community/disko/latest";
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    asahi-fairydust = {
      url = "github:AsahiLinux/linux/fairydust";
      flake = false;
    };
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firmware-abomination = {
      url = "github:MaxCan-Code/firmware-abomination";
      inputs.nixpkgs.follows = "nixpkgs-unfree";
    };
    nixos-hardware.url = "github:masrlinu/nixos-hardware";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
  outputs =
    inputs@{ nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "aarch64-linux"};
      h = import ./home.nix inputs;
      username =
        let
          u = builtins.getEnv "USER";
        in
        if u == "" then "user" else u;
      my.nixpkgs = {
        # https://blog.nobbz.dev/posts/2022-12-12-getting-inputs-to-modules-in-a-flake
        config = {
          # ~/.cache/nixpkgs/pkgs/top-level/config.nix
          # contentAddressedByDefault = true;
          # enableParallelBuildingByDefault = true;
          warnUndeclaredOptions = true;
          allowAliases = false;
          allowUnfree = true;
          checkMeta = true;
          permittedInsecurePackages = [ "electron-39.8.10" ];
        };
      };
    in
    {
      nixosConfigurations =
        let
          inherit (nixpkgs.lib) nixosSystem;
          commons = [
            { inherit (my) nixpkgs; }
            inputs.home-manager.nixosModules.default
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
            inputs.disko.nixosModules.disko
            {
              virtualisation.podman.enable = true;
              virtualisation.podman.dockerCompat = true;
            }
            (
              {
                pkgs,
                lib,
                config,
                ...
              }:
              {
                services.cato-client = {
                  enable = true;
                  package =
                    if pkgs.stdenv.hostPlatform.isAarch64 then
                      pkgs.symlinkJoin (
                        let
                          cato = pkgs.pkgsCross.gnu64.cato-client;
                        in
                        {
                          inherit (cato) pname version;
                          paths = [ cato ];
                          buildInputs = [ pkgs.makeWrapper ];
                          meta = cato.meta // {
                            platforms = [ "aarch64-linux" ];
                          };
                          postBuild = ''
                            for bin in $out/bin/*; do
                              target=$(readlink -f "$bin")
                              rm "$bin"
                              makeWrapper ${pkgs.box64}/bin/box64 "$bin" \
                                --set BOX64_PREFER_EMULATED 1 \
                                --add-flags "$target"
                            done
                          '';
                        }
                      )
                    else
                      pkgs.cato-client;
                };
                systemd.services.cato-client.path = [ pkgs.util-linux ];
                systemd.services.systemd-resolved = lib.mkIf (!config.services.resolved.enable) {
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.coreutils}/bin/true";
                    RemainAfterExit = true;
                  };
                };
              }
            )
          ];
        in
        {
          nixos = nixosSystem {
            modules = commons ++ [
              { home-manager.users.${username} = h; }
              (import ./os.nix username)
              ./os-set.nix
              ./disko-config.nix
              # ./hardware-configuration.nix
              inputs.nixos-hardware.nixosModules.apple-macbook-air-6
              ({ pkgs, ... }: { boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6; })
              {
                hardware.facter.reportPath = ./facter.json;
                hardware.broadcom.wifi.enableLegacyDriverWithKnownVulnerabilities = true;
                boot.binfmt.emulatedSystems = [
                  "aarch64-linux"
                  "riscv64-linux"
                ];
                # boot.kernelParams = ["acpi_backlight=native"];
                hardware.facetimehd = {
                  enable = true;
                  withCalibration = true;
                };
              }
            ];
          };
          len = nixosSystem {
            modules = commons ++ [
              { home-manager.users.${username} = h; }
              (import ./os.nix username)
              ./os-set.nix
              ./disko-len.nix
              {
                hardware.facter.reportPath = ./facter-len.json;
                users.users.root.openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILotBWEbCJQ50vLKF1rc1+6X0we9aF8mmRIsgpy66Po6 user@nixos"
                ];
              }
            ];
          };
          investcloud = nixosSystem {
            modules =
              commons
              ++ (
                let
                  username = "yisun";
                in
                [
                  { home-manager.users.${username} = h; }
                  (import ./os.nix username)
                  ./os-set.nix
                  ./hardware-configuration-dell.nix
                  {
                    networking.hostName = "investcloud";
                    hardware.facter.reportPath = ./facter-dell.json;
                  }
                ]
              );
          };
          asahi = nixosSystem {
            modules =
              commons
              ++ (
                let
                  username = "yisun";
                in
                [
                  { home-manager.users.${username} = h; }
                  (import ./os.nix username)
                  ./os-set.nix
                  # ./disko-m2.nix
                  ./hardware-configuration-m2.nix
                  {
                    networking.hostName = "asahi";
                    hardware.facter.reportPath = ./facter-m2.json;
                    services.thermald.enable = nixpkgs.lib.mkForce false;
                    networking = {
                      networkmanager.wifi.backend = "iwd";
                      # interfaces.wlan0.wakeOnLan.enable = true;
                      # firewall.allowedUDPPorts = [9];
                    };
                    boot.binfmt.emulatedSystems = [
                      "x86_64-linux"
                      "riscv64-linux"
                    ];
                    boot.binfmt.registrations."x86_64-linux".fixBinary = true;
                    system.activationScripts.ldLinuxX86 = ''
                      mkdir -p /lib64
                      ln -sf ${pkgs.pkgsCross.gnu64.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
                    '';
                  }
                  inputs.nixos-apple-silicon.nixosModules.default
                  (
                    {
                      config,
                      lib,
                      ...
                    }:
                    {
                      hardware.asahi.enable = true;
                      hardware.asahi.peripheralFirmwareDirectory =
                        inputs.firmware-abomination.packages.aarch64-linux.default;
                      # tipd hack only reacts to data_status *changes*, so a display
                      # already attached at boot never raises HPD; rebinding the
                      # blessed port's PD controller (front-left = port1 = i2c 0-003f)
                      # replays the transition without a physical re-plug
                      systemd.services.dp-altmode-coldplug = {
                        description = "Rebind port1 PD controller so cold-plugged DP alt mode displays come up";
                        wantedBy = [ "graphical.target" ];
                        after = [ "multi-user.target" ];
                        serviceConfig.Type = "oneshot";
                        script = ''
                          cd /sys/bus/i2c/drivers/tps6598x || exit 0
                          [ -e 0-003f ] || exit 0
                          echo 0-003f > unbind
                          sleep 1
                          echo 0-003f > bind
                        '';
                      };
                      # fairydust branch: experimental USB-C DP alt mode (one blessed port)
                      boot.kernelPackages = lib.mkForce (
                        (config.hardware.asahi.pkgs.linux-asahi.override {
                          _kernelPatches = config.boot.kernelPatches;
                        }).extend
                          (
                            final: prev: {
                              kernel = prev.kernel.overrideAttrs { src = inputs.asahi-fairydust; };
                            }
                          )
                      );
                    }
                  )
                ]
              );
          };
          wsl = nixosSystem {
            modules = commons ++ [
              { home-manager.users.${username} = h; }
              { inherit (import ./os-set.nix) nix environment programs; }
              {
                nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
                wsl = {
                  enable = true;
                  defaultUser = username;
                };
                fileSystems."/mnt/bca" = {
                  device = "\\\\global.root\\dfsAMER\\bca";
                  fsType = "drvfs";
                };
                users = {
                  defaultUserShell = pkgs.zsh;
                  users.${username}.isNormalUser = true;
                };
              }
              inputs.nixos-wsl.nixosModules.default
            ];
          };
        };
      devShells.${pkgs.stdenv.hostPlatform.system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt
          pkgs.statix
        ];
      };
      nixOnDroidConfigurations.default =
        let
          pkgs = import nixpkgs {
            inherit (my.nixpkgs) config;
            system = "aarch64-linux";
            overlays = [ inputs.nix-on-droid.overlays.default ];
          };
        in
        inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          inherit pkgs;
          home-manager-path = inputs.home-manager.outPath;
          modules = [
            {
              nix.extraOptions = "experimental-features = nix-command flakes";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                config = h;
              };
              system.stateVersion = "24.05";
            }
          ];
        };
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          h
          {
            home = {
              inherit username;
              homeDirectory = builtins.getEnv "HOME";
            };
            inherit (my) nixpkgs;
          }
        ];
      };
    };
}
# Local Variables:
# eval: (use-package nix-mode)
# End:

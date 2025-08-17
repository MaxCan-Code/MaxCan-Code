{
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.lix.systems"
      "https://chaotic-nyx.cachix.org"
      "https://watersucks.cachix.org"
      "https://nixos-apple-silicon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
      "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
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
    # nixos-wsl.url = "github:nix-community/NixOS-WSL";
    disko.url = "github:nix-community/disko/latest";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixos-cli = {
      url = "github:nix-community/nixos-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-linux"};
    h = import ./home.nix inputs;
    username = let
      u = builtins.getEnv "USER";
    in
      if u == ""
      then "user"
      else u;
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
      };
      # overlays = [inputs.nixpkgs-wayland.overlays.default];
    };
  in {
    nixosConfigurations = let
      inherit (nixpkgs.lib) nixosSystem;
      commons = [
        {inherit (my) nixpkgs;}
        inputs.home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.disko.nixosModules.disko
      ];
    in {
      nixos = nixosSystem {
        modules =
          commons
          ++ [
            {home-manager.users.${username} = h;}
            (import ./os.nix username)
            ./os-set.nix
            ./disko-config.nix
            ./hardware-configuration.nix
            # {config.facter.reportPath = ./facter.json;}
            {
              nixpkgs.config.permittedInsecurePackages = [
                "broadcom-sta-6.30.223.271-59-6.12.58"
              ];
              services.cato-client.enable = true;
              # boot.kernelParams = ["acpi_backlight=native"];
              # hardware.facetimehd = {
              #   enable = true;
              #   withCalibration = true;
              # };
            }
          ];
      };
      len = nixosSystem {
        modules =
          commons
          ++ [
            {home-manager.users.${username} = h;}
            (import ./os.nix username)
            ./os-set.nix
            ./disko-len.nix
            {config.facter.reportPath = ./facter-len.json;}
            {
              users.users.root.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILotBWEbCJQ50vLKF1rc1+6X0we9aF8mmRIsgpy66Po6 user@nixos"
              ];
            }
          ];
      };
      investcloud = nixosSystem {
        modules =
          commons
          ++ (let
            username = "yisun";
          in [
            {home-manager.users.${username} = h;}
            (import ./os.nix username)
            ./os-set.nix
            {networking.hostName = "investcloud";}
            ./hardware-configuration-dell.nix
          ]);
      };
      asahi = nixosSystem {
        modules =
          commons
          ++ (let
            username = "yisun";
          in [
            {home-manager.users.${username} = h;}
            (import ./os.nix username)
            ./os-set.nix
            {networking.hostName = "asahi";}
            ./hardware-configuration-m2.nix
            {
              services.thermald.enable = nixpkgs.lib.mkForce false;
              networking.networkmanager.wifi.backend = "iwd";
              hardware.asahi.peripheralFirmwareDirectory = ./firmware;
            }
            inputs.nixos-apple-silicon.nixosModules.default
          ]);
      };
      wsl = nixosSystem {
        modules =
          commons
          ++ [
            {home-manager.users.wsl = h;}
            {inherit (import ./os-set.nix) nix environment programs;}
            {
              nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
              wsl = {
                enable = true;
                defaultUser = "wsl";
              };
              fileSystems."/mnt/bca" = {
                device = "\\\\global.root\\dfsAMER\\bca";
                fsType = "drvfs";
              };
              users = {
                defaultUserShell = pkgs.zsh;
                users.wsl.isNormalUser = true;
              };
            }
            inputs.nixos-wsl.nixosModules.default
          ];
      };
    };

    devShells.${pkgs.stdenv.hostPlatform.system}.default = pkgs.mkShell {
      packages = [
        pkgs.nixfmt-rfc-style
        pkgs.alejandra
        pkgs.statix
      ];
    };

    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        h
        {
          home = {
            inherit username;
            homeDirectory = /. + builtins.getEnv "HOME"; # ~/.
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


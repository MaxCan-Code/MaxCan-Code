{
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.lix.systems"
      "https://chaotic-nyx.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-option-search = {
      url = "github:ciderale/nix-option-search";
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
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko/latest";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = inputs @ {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-linux"};
    home-with-inputs = import ./home.nix inputs;
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
        inputs.lix-module.nixosModules.default
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.disko.nixosModules.disko
      ];
    in {
      nixos = nixosSystem {
        modules =
          commons
          ++ [
            {home-manager.users.${username} = home-with-inputs;}
            ./os.nix
            ./os-set.nix
            ./disko-config.nix
            ./hardware-configuration.nix
            # {
            #   hardware.facetimehd = {
            #     enable = true;
            #     withCalibration = true;
            #   };
            # }
          ];
      };
      len = nixosSystem {
        modules =
          commons
          ++ [
            {home-manager.users.${username} = home-with-inputs;}
            ./os.nix
            ./os-set.nix
            {
              users.users.root.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILotBWEbCJQ50vLKF1rc1+6X0we9aF8mmRIsgpy66Po6 user@nixos"
              ];
            }
            ./disko-len.nix
            {config.facter.reportPath = ./facter-len.json;}
          ];
      };
      wsl = nixosSystem {
        modules =
          commons
          ++ [
            ./wsl.nix
            {
              users = {
                defaultUserShell = pkgs.zsh;
                users.wsl.isNormalUser = true;
              };
            }
            {home-manager.users.wsl = home-with-inputs;}
            inputs.nixos-wsl.nixosModules.default
          ];
      };
    };

    devShells.${pkgs.system}.default = pkgs.mkShell {
      packages = [
        pkgs.nixfmt-rfc-style
        pkgs.alejandra
        pkgs.statix
      ];
    };

    homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        home-with-inputs
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


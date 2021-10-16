{
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://nixpkgs-update.cachix.org"
      "https://cache.ngi0.nixos.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8="
      "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  inputs = {
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    ride = {
      url = "github:MaxCan-Code/ride/tbt_support";
      flake = false;
    };
    kakoune = {
      url = "github:mawww/kakoune";
      flake = false;
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-2.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko/latest";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-linux"};
      home-with-inputs = import ./home.nix inputs;
      username =
        let
          u = builtins.getEnv "USER";
        in
        if u == "" then "user" else u;
      my.nixpkgs = {
        # https://blog.nobbz.dev/posts/2022-12-12-getting-inputs-to-modules-in-a-flake
        config = {
          # contentAddressedByDefault = true; # https://wiki.nixos.org/wiki/ca-derivations
          # enableParallelBuildingByDefault = true;
          warnUndeclaredOptions = true;
          allowAliases = false;
          allowUnfree = true;
          checkMeta = true;
        };
        overlays = [ inputs.nixpkgs-wayland.overlays.default ];
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
            inputs.nix-index-database.nixosModules.nix-index
            {
              programs.nix-index-database.comma.enable = true;
              programs.command-not-found.enable = false;
            }
            inputs.lix-module.nixosModules.default
            # inputs.nixos-facter-modules.nixosModules.facter
            # inputs.disko.nixosModules.disko
          ];
        in
        {
          nixos = nixosSystem {
            modules = commons ++ [
              { home-manager.users.${username} = home-with-inputs; }
              ./os.nix
              ./os-set.nix
              ./disko-config.nix
              ./hardware-configuration.nix
              # ./disko-len.nix
              # ./len.nix
              # { config.facter.reportPath = ./facter.json; }
            ];
          };
          wsl = nixosSystem {
            modules = commons ++ [
              ./wsl.nix
              {
                users = {
                  defaultUserShell = pkgs.zsh;
                  users.wsl.isNormalUser = true;
                };
              }
              { home-manager.users.wsl = home-with-inputs; }
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

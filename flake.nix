{
  description = "from https://github.com/LnL7/nix-darwin/tree/master/modules/examples";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      nix.package = pkgs.nixFlakes;
      services.nix-daemon.enable = true;
    };
  in
  {
    # Build darwin flake using:
    # $ ~/.dotfiles/result/sw/bin/darwin-rebuild switch --flake ~/.dotfiles \
    #       --override-input darwin .
    darwinConfigurations."home" = darwin.lib.darwinSystem {
      modules = [ configuration darwin.darwinModules.simple ];
      # modules = [ configuration (import ./simple.nix) ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."home".pkgs;
  };
}

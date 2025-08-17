flake-inputs: inputs @ {pkgs, ...}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    neovim = {
      # package = flake-inputs.neovim-nightly-overlay.packages.${system}.default;
      # enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages =
        builtins.attrValues {
          inherit
            (pkgs)
            fnlfmt # remake
            ripgrep
            zig
            ;
        }
        ++ [pkgs.luajitPackages.fennel];
    };
  };
  home = {
    stateVersion = "25.11";
    packages =
      builtins.attrValues {
        inherit # https://nix.dev/guides/best-practices#with-scopes
          (pkgs)
          comma
          nh
          difftastic
          jujutsu
          gh
          glab
          nyxt
          qutebrowser
          tmux
          ruby
          yazi
          i3status
          activate-linux
          mpv
          rlwrap
          cbqn
          ;
      }
      ++ [
        flake-inputs.nixos-cli.packages.${system}.nixos
        (pkgs.kakoune-unwrapped.overrideAttrs {src = flake-inputs.kakoune;})
        pkgs.perl
        (pkgs.symlinkJoin {
          name = "emacs-pgtk";
          paths = [pkgs.emacs-pgtk];
          buildInputs = [pkgs.makeWrapper];
          postBuild = "wrapProgram $out/bin/emacs --suffix PATH : ${
            inputs.lib.makeBinPath [pkgs.mupdf pkgs.poppler-utils]
          }"; # tectonic graphicsmagick-imagemagick-compat
        })
        (pkgs.aspellWithDicts (d: [
          d.en
          d.en-computers
        ])) # enchant skyspell
        # lset-extra-dicts en-computers.rws:en-science.rws
        # nix edit nixpkgs#aspellDicts.en
        (pkgs.dyalog.override {
          acceptLicense = true;
          dotnetSupport = true;
          htmlRendererSupport = true;
          sqaplSupport = true;
          zeroFootprintRideSupport = true;
          enableDocs = true;
        })
        (pkgs.ride.overrideAttrs (prev: {
          src = flake-inputs.ride;
        }))
      ];
  };
}

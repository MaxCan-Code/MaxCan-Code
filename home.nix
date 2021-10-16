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
    stateVersion = "25.05";
    # https://nix.dev/guides/best-practices#with-scopes
    packages =
      builtins.attrValues {
        inherit
          (pkgs)
          comma
          gh
          nh
          difftastic
          jujutsu
          nyxt
          qutebrowser
          tmux
          ruby
          emacs30-pgtk
          i3status
          activate-linux
          mpv
          rlwrap # cbqn uiua ngn-k
          ;
      }
      ++ [
        (pkgs.symlinkJoin {
          name = "kakoune";
          paths = [(pkgs.kakoune-unwrapped.overrideAttrs {src = flake-inputs.kakoune;})];
          buildInputs = [pkgs.makeWrapper];
          postBuild = "wrapProgram $out/bin/kak --suffix PATH : ${inputs.lib.makeBinPath [pkgs.python314 pkgs.perl]}";
        })
        flake-inputs.nix-option-search.packages.${system}.default
        # flake-inputs.emacs-overlay.packages.${system}.emacs-pgtk # tectonic graphicsmagick-imagemagick-compat
        (pkgs.aspellWithDicts (d: [
          d.en
          d.en-computers
        ])) # enchant skyspell
        # lset-extra-dicts en-computers.rws:en-science.rws
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/aspell/dictionaries.nix#L22
        # (pkgs.agda.withPackages (p: [p.standard-library]))
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
          patches = inputs.lib.elemAt prev.patches 1;
        }))
      ];
  };
}

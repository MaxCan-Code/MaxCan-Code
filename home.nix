{
  neovim-nightly-overlay,
  emacs-overlay,
  dyalog,
  ride,
  ...
}: {pkgs, ...} @ inputs: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  programs = {
    home-manager.enable = true; # Let Home Manager install and manage itself.
    neovim = {
      package = neovim-nightly-overlay.packages.${system}.default;
      enable = true;
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
    stateVersion = "24.05";
    # https://nix.dev/anti-patterns/language#with-attrset-expression
    packages =
      builtins.attrValues {
        inherit
          (pkgs)
          gh
          nh
          difftastic
          nyxt
          qutebrowser # librewolf-wayland
          tmux
          ruby
          python3 # tectonic graphicsmagick-imagemagick-compat
          enchant # skyspell
          wmenu
          i3status
          activate-linux
          ddcutil
          ;
      }
      ++ [
        emacs-overlay.packages.${system}.emacs-pgtk
        (pkgs.aspellWithDicts (d: [d.en d.en-computers]))
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/aspell/dictionaries.nix#L22
        # lset-extra-dicts en-computers.rws:en-science.rws
        # (pkgs.agda.withPackages (p: [p.standard-library]))
        (pkgs.callPackage (dyalog + /pkgs/by-name/dy/dyalog/package.nix) {
          acceptLicense = true;
          dotnetSupport = true;
          htmlRendererSupport = true;
          sqaplSupport = true;
          zeroFootprintRideSupport = true;
          enableDocs = true;
        })
        ride.legacyPackages.${system}.ride
        (pkgs.kakoune-unwrapped.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "mawww";
            repo = "kakoune";
            rev = "master";
            # hash = inputs.lib.fakeHash;
            hash = "sha256-s9pczG5UCc76K1Z1FdK/FBX+nO6jIixPvpmO+bcomvY=";
          };
          patches = [];
          version = "master";
        })
      ];
  };
}

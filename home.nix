flake-inputs:
{ pkgs, ... }@inputs:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  programs = {
    home-manager.enable = true;
    neovim = {
      package = flake-inputs.neovim-nightly-overlay.packages.${system}.default;
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages =
        builtins.attrValues {
          inherit (pkgs)
            fnlfmt # remake
            ripgrep
            zig
            ;
        }
        ++ [ pkgs.luajitPackages.fennel ];
    };
  };
  home = {
    stateVersion = "24.11";
    # https://nix.dev/guides/best-practices#with-scopes
    packages =
      builtins.attrValues {
        inherit (pkgs)
          gh
          nh
          difftastic
          nyxt
          qutebrowser
          tmux
          ruby
          python3
          rlwrap
          cbqn
          scryer-prolog
          swiProlog
          i3status
          activate-linux
          ;
      }
      ++ [
        flake-inputs.emacs-overlay.packages.${system}.emacs-pgtk
        # tectonic graphicsmagick-imagemagick-compat
        (pkgs.aspellWithDicts (d: [
          d.en
          d.en-computers
        ])) # enchant skyspell
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/aspell/dictionaries.nix#L22
        # lset-extra-dicts en-computers.rws:en-science.rws
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
        (pkgs.kakoune-unwrapped.overrideAttrs { src = flake-inputs.kakoune; })
      ];
  };
}

flake-inputs:
inputs@{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  home = {
    stateVersion = "26.11";
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
          i3status
          activate-linux
          rlwrap
          cbqn
          uiua-unstable
          # rr.thread perf
          ;
      }
      ++
        map
          (
            let
              inherit (inputs.lib)
                flip
                pipe
                zipListsWith
                nameValuePair
                ;
              inherit (builtins) listToAttrs;
            in
            flip pipe [
              (zipListsWith nameValuePair [
                "pkg"
                "deps"
              ])
              listToAttrs
              (
                {
                  pkg,
                  deps,
                }:
                pkgs.symlinkJoin {
                  inherit (pkg) name;
                  paths = map (o: pkg.${o}) pkg.outputs;
                  buildInputs = [ pkgs.makeWrapper ];
                  postBuild = "wrapProgram $out/bin/${pkg.meta.mainProgram} \\
                                 --suffix PATH : ${inputs.lib.makeBinPath deps}";
                }
              )
            ]
          )
          [
            [
              (pkgs.kakoune-unwrapped.overrideAttrs {
                src = flake-inputs.kakoune;
              })
              [ pkgs.perl ]
            ]
            [
              pkgs.tmux
              (map
                (
                  plugin:
                  pkgs.symlinkJoin {
                    inherit (plugin) name;
                    paths = [ plugin ];
                    buildInputs = [ pkgs.makeWrapper ];
                    postBuild = "makeWrapper ${plugin.rtp} $out/bin/${baseNameOf plugin.rtp}";
                  }
                )
                [
                  (pkgs.tmuxPlugins.jump.overrideAttrs {
                    # PR schasse/tmux-jump#50: row-then-column walk fixes vi-mode
                    # drift on tmux 3.7; rectangle-select cursor-down avoids the
                    # sticky-$ misjump when the top row is blank (#49 hit it, see
                    # issue #46). Drop once merged upstream.
                    src = pkgs.fetchFromGitHub {
                      owner = "arcaartem";
                      repo = "tmux-jump";
                      rev = "6cf4163b7fdbc5333eb5dcd2f04d11815f58bdfa";
                      hash = "sha256-ia9AfVa6akDEzZVcESVqwnY3nB1uLbxU1ZlBH1j1/tk=";
                    };
                  })
                  pkgs.tmuxPlugins.fingers
                  (pkgs.tmuxPlugins.extrakto.overrideAttrs {
                    postPatch =
                      let
                        # skim's --expect is deprecated/broken; accept(key) restores the
                        # query/key/selection output shape extrakto's dispatch parses
                        sk-extrakto = pkgs.writeShellScriptBin "sk-extrakto" ''
                          export SKIM_DEFAULT_OPTIONS="--bind ${
                            inputs.lib.concatMapStringsSep "," (k: "${k}:accept(${k})") [
                              "enter"
                              "tab"
                              "esc"
                              "ctrl-c"
                              "ctrl-f"
                              "ctrl-e"
                              "ctrl-o"
                              "ctrl-g"
                            ]
                          },${
                            # help on ^_ (0x1f: ctrl-7 legacy / ctrl-_ kitty) and ^? (0x7f);
                            # emits ctrl-h, the key extrakto dispatches to its help screen
                            inputs.lib.concatMapStringsSep "," (k: "${k}:accept(ctrl-h)") [
                              "ctrl-7"
                              "ctrl-_"
                              "bspace"
                            ]
                          }"
                          out=$(${pkgs.skim}/bin/sk "$@")
                          rc=$?
                          # extrakto unpacks query\nkey[\nselection..]; skim's abort paths
                          # (ctrl-d, panics) emit 0-1 lines — turn those into a cancel, log raw bytes
                          case $out in
                            *$'\n'*) printf '%s\n' "$out" ;;
                            *)
                              printf 'rc=%s out=[%s]\n' "$rc" "$out" \
                                >> "''${XDG_STATE_HOME:-$HOME/.local/state}/sk-extrakto.log"
                              printf '\nesc\n'
                              ;;
                          esac
                          exit $rc
                        '';
                      in
                      ''
                        substituteInPlace extrakto_plugin.py \
                          --replace-fail '"@extrakto_fzf_tool": "fzf",' \
                            '"@extrakto_fzf_tool": "${sk-extrakto}/bin/sk-extrakto",'
                      '';
                  })
                ]
              )
            ]
            [
              pkgs.emacs31-pgtk
              [
                pkgs.mupdf
                pkgs.poppler-utils
              ]
            ] # tectonic graphicsmagick-imagemagick-compat
          ]
      ++ [
        (pkgs.mpv.override {
          mpv-unwrapped = pkgs.mpv-unwrapped.override {
            sixelSupport = true;
          };
        })
        (pkgs.aspellWithDicts (d: [ d.en ])) # enchant skyspell
        # lset-extra-dicts en-computers.rws:en-science.rws
        # nix edit nixpkgs#aspellDicts.en
        (pkgs.dyalog.override {
          acceptLicense = true;
          dotnetSupport = true;
          # htmlRendererSupport = true;
          sqaplSupport = true;
          zeroFootprintRideSupport = true;
          enableDocs = true;
        })
        ((pkgs.ride.override { electron = pkgs.electron_39; }).overrideAttrs (prev: {
          src = flake-inputs.ride;
          # must track the ride input's package-lock.json as modified by nixpkgs' patches;
          # recompute with lib.fakeHash on `nix flake update ride`
          npmDeps = pkgs.fetchNpmDeps {
            src = flake-inputs.ride;
            inherit (prev) patches;
            postPatch = prev.postPatch or "";
            hash = "sha256-RyZh+MocTLLKdh3Aq/7sodf3jYPlXt95hXo6j0PpEIQ=";
          };
        }))
      ];
  };
}

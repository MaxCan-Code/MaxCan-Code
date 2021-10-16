(.load-autoconfig config False)
(setv (. c content private-browsing) True
      (. c keyhint delay) 0
      (. c messages timeout) 600
      (. c scrolling bar) "always"
      (. c statusbar position) "top"
      (. c tabs show) "never"
      (. c url searchengines) {"DEFAULT" "https://marginalia-search.com/search?query={}"
                                     "s" "https://searx.neocities.org/#q={}"
                                     "n" "https://mynixos.com/search?q={}"
                                    "nn" "https://search.nixos.org/packages?channel=unstable&query={}"}
      (. c url start-pages) ["qute://start"]
      (. c zoom default) "115%"
      (. c fonts default-size) "17pt"
      (. c window transparent) True
      (. c window hide-decoration) True
      (. c editor command) ["foot" "kak" "{file}"])
(.bind config "Sd" "history-clear")

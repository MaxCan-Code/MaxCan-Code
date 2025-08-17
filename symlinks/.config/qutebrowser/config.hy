(.load-autoconfig config False)
(setv (. c content private-browsing) True
      (. c keyhint delay) 0
      (. c messages timeout) 600
      (. c scrolling bar) "always"
      (. c statusbar position) "top"
      (. c tabs show) "never"
      (. c url searchengines) {"DEFAULT" "https://search.brave.com/search?q={}"
                                    "nn" "https://search.nixos.org/packages?channel=unstable&query={}"
                                     "m" "https://old-search.marginalia.nu/search?query={}"
                                     "n" "https://mynixos.com/search?q={}"}
      (. c url start-pages) ["qute://start"]
      (. c fonts default-size) "17pt"
      (. c window transparent) True
      (. c window hide-decoration) True
      (. c editor command) ["foot" "kak" "{file}"])
(.bind config "Sd" "history-clear")
(.bind config "ge" "edit-url")

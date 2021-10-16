; ((fn [q] (print (hy.disassemble q True))) '(
(.load_autoconfig config False)
(setv (. c content private_browsing) True
      (. c keyhint delay) 0
      (. c messages timeout) 600
      (. c scrolling bar) "always"
      (. c statusbar position) "top"
      (. c tabs show) "never"
      (. c url searchengines) {"DEFAULT" "https://search.atlas.engineer/searxng/search?q={}"
                               "b"       "https://search.brave.com/search?q={}"
                               "n"       "https://search.nixos.org/packages?channel=unstable&query={}"}
      (. c url open_base_url) True
      (. c url start_pages) "qute://start"
      (. c zoom default) "115%"
      (. c fonts default-size) "17pt"
      (. c window transparent) True
      (. c window hide-decoration) True
      (. c editor command) [ "foot" "kak" "{file}" ])
(.bind config "Sd" "history-clear")
; ))

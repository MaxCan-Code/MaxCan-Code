(.load_autoconfig config False)

(setv (. c content private_browsing) True
      (. c keyhint delay) 0
      (. c messages timeout) 600
      (. c scrolling bar) "always"
      (. c statusbar position) "top"
      (. c tabs show) "never"
      (. c url searchengines) {"DEFAULT" "https://search.brave.com/search?q={}"}
      (. c url start_pages) "qute://help/img/cheatsheet-big.png"
      (. c zoom default) "140%"
      (. c fonts default_size) "24pt")

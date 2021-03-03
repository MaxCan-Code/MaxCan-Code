;; load standard vis module, providing parts of the Lua API
(require :vis)

(vis.events.subscribe
  vis.events.INIT
  (lambda []
    "Your global configuration options"
    (vis:command "se theme nu")))

(vis.events.subscribe
  vis.events.WIN_OPEN
  (lambda [win]
    "
    Your per window configuration options e.g.
    vis:command('set number')
    "
    (vis:command "se cul")
    (vis:command "se rnu")
    (vis:command "se show-newlines on")
    (vis:command "se show-spaces on")
    ;; (vis:command "se show-tabs on")
    (vis:command "unmap normal S")
    (vis:command "unmap normal s")
    (vis:command "unmap normal O")
    (vis:command "map! normal o :<Up><Escape>zbj")
    (vis:command "unmap normal X")
    (vis:command "unmap normal x")
    (vis:command "map! normal ? /<Up><Escape>zbj")
    (vis:command "map! normal <C-w>q :q<Enter>")))

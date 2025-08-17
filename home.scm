;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "nyxt"
                                            "qutebrowser"
                                            "tmux"
                                            "ruby"
                                            "emacs"
                                            "i3status"
                                            "mpv"
                                            "rlwrap"
                                            "dyalog"
                                            "kakoune")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (append (list) %base-home-services)))

;; Local Variables:
;; eval: (use-package guix)
;; eval: (use-package geiser)
;; Info-additional-directory-list: ("~/.config/guix/current/share/info")
;; End:

;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu packages)
             (gnu packages base)
             (gnu services))

(define my-glibc-locales
  (make-glibc-utf8-locales glibc
                           #:locales (list "en_CA")
                           #:name "glibc-canadian-utf8-locales"))

(home-environment
  (packages (list glibc-canadian-utf8-locales))
  (services (list (service home-zsh-service-type
                           (home-zsh-configuration)))))

;; Local Variables:
;; eval: (use-package guix)
;; eval: (use-package geiser)
;; Info-additional-directory-list: ("~/.config/guix/current/share/info")
;; End:

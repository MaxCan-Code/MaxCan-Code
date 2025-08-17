(define-configuration buffer
  ((default-modes (append '(nyxt/mode/vi:vi-normal-mode) %slot-value%))))
(define-configuration prompt-buffer
  ((default-modes (append '(nyxt/mode/vi:vi-insert-mode) %slot-value%))))
(define-configuration web-buffer
  ((default-modes (append '(reduce-tracking-mode) %slot-value%))))

(define-command-global scroll-half-page-down ()
  "Scroll down by half page height."
  (ps-eval (ps:chain window (scroll-by 0 (* (ps:lisp (page-scroll-ratio (current-buffer)))
                                          (/ (ps:@ window inner-height) 2))))))
(define-command-global scroll-half-page-up ()
  "Scroll up by half page height."
  (ps-eval (ps:chain window (scroll-by 0 (- (* (ps:lisp (page-scroll-ratio (current-buffer)))
                                             (/ (ps:@ window inner-height) 2)))))))

(define-configuration :base-mode
  ((keyscheme-map
    (keymaps:define-keyscheme-map
     "custom" (list :import %slot-value%)
     nyxt/keyscheme:vi-normal
     (list "C-d" 'scroll-half-page-down "C-u" 'scroll-half-page-up
           "; y" 'copy-hint-url "B" 'nothing "C-t" 'nothing
           "C-m" 'run-action-on-return "g u" 'go-up
           "S h" 'history-tree "g r" 'load-config-file
           "g i" 'focus-first-input-field "C-h a" 'describe-any)))))

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
(defmacro with-muffled-override (&body body)
  `(handler-bind ((nkeymaps:override-existing-binding #'muffle-warning))
     ,@body))
(define-configuration :base-mode
  ((keyscheme-map
    (with-muffled-override
      (keymaps:define-keyscheme-map
       "custom" (list :import %slot-value%)
       nyxt/keyscheme:vi-normal
       (list "C-d" 'scroll-half-page-down "C-u" 'scroll-half-page-up
             "; y" 'copy-hint-url "B" 'nothing "C-t" 'nothing
             "C-q" 'nyxt:quit "g u" 'go-up
             "S h" 'history-tree "g r" 'load-config-file
             "g i" 'focus-first-input-field "f1 a" 'describe-any))))))
(define-configuration nyxt/mode/vi:vi-normal-mode
  ((keyscheme-map
    (with-muffled-override
      (keymaps:define-keyscheme-map
       "custom-vi-normal" (list :import %slot-value%)
       nyxt/keyscheme:vi-normal
       (list "C-s" 'nyxt/mode/prompt-buffer:toggle-suggestions-display))))))
(define-configuration nyxt/mode/vi:vi-insert-mode
  ((keyscheme-map
    (with-muffled-override
      (keymaps:define-keyscheme-map
       "custom-vi-insert" (list :import %slot-value%)
       nyxt/keyscheme:vi-insert
       (list "C-q" 'nyxt:quit
             "C-s" 'nyxt/mode/prompt-buffer:toggle-suggestions-display
             "C-h" 'nyxt/mode/input-edit:delete-backwards))))))
(let ((orig nkeymaps:*translator*)
      (remaps (mapcar (lambda (pair)
                        (cons (nkeymaps:make-key :value (car pair)
                                                 :modifiers (list nkeymaps:+control+))
                              (nkeymaps:make-key :value (cdr pair))))
                      '(("[" . "escape") ("m" . "return") ("/" . "f1")))))
  (setf nkeymaps:*translator*
        (lambda (keys)
          (if (some (lambda (k)
                      (some (lambda (r) (nkeymaps:key= k (car r))) remaps))
                    keys)
              (cons (mapcar (lambda (k)
                              (let ((hit (find-if (lambda (r) (nkeymaps:key= k (car r))) remaps)))
                                (if hit (cdr hit) k)))
                            keys)
                    (funcall orig keys))
              (funcall orig keys)))))

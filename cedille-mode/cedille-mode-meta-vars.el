;;;;;;;;;; Cedille Meta-Vars Buffer ;;;;;;;;;;

(defstruct meta-var kind sol cm file start-intro end-intro start-sol end-sol)

(defvar cedille-mode-meta-vars-list nil
  "List of (name . meta-var)")


(defgroup cedille-meta-vars nil
  "Meta-Vars options for Cedille"
  :group 'cedille)

(defface cedille-meta-vars-head-face
  '((((background light)) (:slant italic))
    (((background dark)) (:slant italic)))
  "The face used for the head in a meta-vars locale"
  :group 'cedille-meta-vars)

(defface cedille-meta-vars-args-face
  '((((background light)) (:box (:line-width -1)))
    (((background dark)) (:box (:line-width -1))))
  "The face used for the arguments in a meta-vars locale"
  :group 'cedille-meta-vars)


(defun cedille-mode-meta-vars-continue-computation (node &optional allow-locale)
  "Returns t if you should keep computing meta variables in the first child of NODE"
  (when node
    (let* ((keywords (cdr (assoc 'keywords (se-term-data node))))
           (is-application (when keywords (member "application" (split-string keywords " "))))
           (is-locale (when keywords (member "meta-var-locale" (split-string keywords " ")))))
      (and is-application (or allow-locale (not is-locale))))))

(defun cedille-mode-meta-vars-split (meta-var)
  "Splits the string \"name [cm] value\" (cm is optional) into triple (name . cm . value)"
  (let ((split (split-string meta-var " ")))
    (cons (car split) (cons (cadr split) (mapconcat 'identity (cddr split) " ")))))

(defun cedille-mode-meta-vars-collect (key alist)
  "Collects all values from ALIST with key KEY into a list"
  (when alist
    (if (string= key (caar alist))
        (cons (cedille-mode-meta-vars-split (cdar alist))
              (cedille-mode-meta-vars-collect key (cdr alist)))
      (cedille-mode-meta-vars-collect key (cdr alist)))))

(defun cedille-mode-compute-meta-vars-h (node &optional allow-locale)
  (when (cedille-mode-meta-vars-continue-computation node allow-locale)
    (let* ((data (se-term-data node))
           (introduced-meta-vars (reverse (cedille-mode-meta-vars-collect 'meta-vars-intro data)))
           (solved-meta-vars (reverse (cedille-mode-meta-vars-collect 'meta-vars-sol data)))
           (meta-vars (cedille-mode-compute-meta-vars-h (car (se-node-children node)))))
      (while introduced-meta-vars
        (let* ((name-kind (pop introduced-meta-vars))
               (name (intern (car name-kind)))
               (kind (cddr name-kind))
               (mv (or
                    (cdr (assoc name meta-vars))
                    (make-meta-var
                     :kind kind
                     :file (buffer-file-name)
                     :start-intro (se-term-start node)
                     :end-intro (se-term-end node)))))
          (setq meta-vars (cedille-mode-set-assoc-value meta-vars name mv))))
      (while solved-meta-vars
        (let* ((name-cm-sol (pop solved-meta-vars))
               (name (intern (car name-cm-sol)))
               (cm (cadr name-cm-sol))
               (sol (cddr name-cm-sol))
               (mv (cdr (assoc name meta-vars)))) ; Assumed to exist
          (setf (meta-var-sol mv) sol
                (meta-var-cm mv) cm
                (meta-var-start-sol mv) (se-term-start node)
                (meta-var-end-sol mv) (se-term-end node))
          (setf (cdr (assoc name meta-vars)) mv)))
      meta-vars)))

(defun cedille-mode-compute-meta-vars()
  "Computes the meta-variables at the current node"
  (when se-mode-selected
    (setq cedille-mode-meta-vars-list
          (cedille-mode-compute-meta-vars-h (se-mode-selected) t))))

(defun cedille-mode-meta-var-text(name mv)
  "Returns the text for the display of a single meta-variable MV"
  (concat
   (se-pin-data 0 (length name) 'loc (list (cons 'fn (meta-var-file mv)) (cons 's (number-to-string (meta-var-start-intro mv))) (cons 'e (number-to-string (meta-var-end-intro mv)))) name)
   " : "
   (meta-var-kind mv)
   (when (meta-var-sol mv)
     (concat
      (se-pin-data 1 2 'loc (list (cons 'fn (meta-var-file mv)) (cons 's (number-to-string (meta-var-start-sol mv))) (cons 'e (number-to-string (meta-var-end-sol mv)))) (if (string= (meta-var-cm mv) "checking") " ◂ " " = "))
      (meta-var-sol mv)
      ))
   "\n"))

(defun cedille-mode-display-meta-vars()
  (let ((parent cedille-mode-parent-buffer))
    (with-current-buffer (cedille-mode-meta-vars-buffer)
      (setq cedille-mode-parent-buffer parent
            buffer-read-only nil)
      (erase-buffer)
      (let ((meta-vars cedille-mode-meta-vars-list))
        (while meta-vars
          (insert (cedille-mode-meta-var-text (symbol-name (caar meta-vars)) (cdar meta-vars)))
          (setq meta-vars (cdr meta-vars))))
      (goto-char 1)
      (setq buffer-read-only t)
      (setq deactivate-mark nil))))



(defun cedille-mode-meta-vars-find-locale-end(nodes)
  (when nodes
    (if (cedille-mode-meta-vars-continue-computation (car nodes))
        (cedille-mode-meta-vars-find-locale-end (cdr nodes))
      (car nodes))))

(defun cedille-mode-meta-vars-find-locale-start(node &optional allow-locale)
  (when node
    (if (cedille-mode-meta-vars-continue-computation node allow-locale)
        (cedille-mode-meta-vars-find-locale-start (car (se-node-children node)))
      node)))

(defun cedille-mode-fontify-meta-vars-start(node)
  (when node
    (overlay-put
     (make-overlay (se-term-start node) (se-term-end node)
                   (or cedille-mode-parent-buffer (current-buffer)))
     'face 'cedille-meta-vars-head-face)))

(defun cedille-mode-fontify-meta-vars-end(node)
  (when node
    (overlay-put
     (make-overlay (se-term-start node) (se-term-end node)
                   (or cedille-mode-parent-buffer (current-buffer)))
     'face 'cedille-meta-vars-args-face)))

(defun cedille-mode-fontify-meta-vars()
  (with-current-buffer (or cedille-mode-parent-buffer (current-buffer))
    (with-silent-modifications
      (remove-overlays nil nil 'face 'cedille-meta-vars-head-face)
      (remove-overlays nil nil 'face 'cedille-meta-vars-args-face)
      ; Make sure the meta-vars buffer is open and the selected span is an application
      (when (and (get-buffer-window (cedille-mode-meta-vars-buffer-name))
                 (cedille-mode-meta-vars-continue-computation (se-mode-selected) t))
        (cedille-mode-fontify-meta-vars-start
         (cedille-mode-meta-vars-find-locale-start (se-mode-selected) t))
        (cedille-mode-fontify-meta-vars-end
         (cedille-mode-meta-vars-find-locale-end
          (cons (se-mode-selected) se-mode-not-selected)))))))


(defun cedille-mode-meta-vars()
  (cedille-mode-compute-meta-vars)
  (cedille-mode-fontify-meta-vars)
  (cedille-mode-display-meta-vars)
  (cedille-mode-rebalance-windows))

(defun cedille-mode-meta-vars-buffer-name()
  (with-current-buffer (or cedille-mode-parent-buffer (current-buffer))
    (concat "*cedille-meta-vars-" (cedille-mode-current-buffer-base-name) "*")))

(defun cedille-mode-meta-vars-buffer()
  (get-buffer-create (cedille-mode-meta-vars-buffer-name)))

(defun cedille-mode-meta-vars-close-window-fn()
  (lambda ()
    (interactive)
    (cedille-mode-close-active-window)
    (cedille-mode-fontify-meta-vars)))


(define-minor-mode cedille-meta-vars-mode
  "Creates meta-vars-mode"
  nil
  " Meta-Vars"
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map cedille-mode-minor-mode-parent-keymap)
    (define-key map (kbd "m") (cedille-mode-meta-vars-close-window-fn))
    (define-key map (kbd "M") (cedille-mode-meta-vars-close-window-fn))
    (define-key map (kbd "h") (make-cedille-mode-info-display-page "meta-vars buffer"))
    map)
  (when cedille-meta-vars-mode
    (set-input-method "Cedille")))

(provide 'cedille-mode-meta-vars)

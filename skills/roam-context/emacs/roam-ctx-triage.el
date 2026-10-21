;;; roam-ctx-triage.el --- Triage agent captures into org-roam -*- lexical-binding: t; -*-

;; Author: chazu
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (org "9.6") (org-roam "2.2"))
;; Keywords: outlines convenience

;;; Commentary:

;; REFERENCE COPY: the maintained version lives in the author's private
;; dotfiles repository.  Updates to this copy are best-effort only.

;; Agents append captures to dated files in an inbox directory with the
;; `roam-ctx' CLI.  Each capture is a top-level heading whose properties carry
;; a one-line SUMMARY and a filing recommendation: FILE_TO is "new" or a node
;; id, and FILE_UNDER is an optional heading path ("A > B") inside that node.
;;
;; `M-x roam-ctx-triage' shows one capture at a time.  Keys:
;;
;;   f  file where recommended      F  file elsewhere (pick note and heading)
;;   d  discard                     e  edit, then C-c C-c to resume
;;   n  next      p  previous       q  quit
;;
;; Filing never assigns an ID inside the inbox, so org-roam never indexes it.
;; New notes are written directly into `org-roam-directory'; captures filed
;; into an existing note become child headings there.  Discarded captures are
;; appended to .discarded.org in the inbox directory.

;;; Code:

(require 'org)
(require 'org-capture)
(require 'org-id)
(require 'org-roam)

(defgroup roam-ctx-triage nil
  "Triage agent captures into org-roam."
  :group 'org-roam)

(defcustom roam-ctx-triage-inbox-directory
  (or (getenv "ROAM_CTX_INBOX") "~/org/agent-inbox")
  "Directory holding dated capture files written by `roam-ctx capture'."
  :type 'directory)

(defcustom roam-ctx-triage-share-tag
  (or (getenv "ROAM_CTX_TAG") "agent")
  "Tag that shares a note with agents.
Kept on new notes; dropped from captures filed into an existing note,
which is already shared."
  :type 'string)

(defcustom roam-ctx-triage-kept-properties
  '("SUMMARY" "CAPTURED" "SOURCE" "REPO" "BRANCH" "COMMIT" "CWD")
  "Capture properties copied into the filed note."
  :type '(repeat string))

;;;; Reading a capture

(defun roam-ctx-triage--entries ()
  "Return the number of captures in the current buffer."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let ((n 0))
        (while (re-search-forward "^\\* " nil t) (setq n (1+ n)))
        n))))

(defun roam-ctx-triage--goto-entry ()
  "Move to the heading of the capture at point, or signal an error."
  (widen)
  (unless (ignore-errors (org-back-to-heading t) t)
    (user-error "Not on a capture"))
  (while (> (org-current-level) 1) (org-up-heading-safe)))

(defun roam-ctx-triage--capture ()
  "Return the capture at point as a plist."
  (save-excursion
    (roam-ctx-triage--goto-entry)
    (let* ((beg (point))
           (end (save-excursion (org-end-of-subtree t t)))
           (body-beg (save-excursion (org-end-of-meta-data t) (point))))
      (list :title (org-get-heading t t t t)
            :tags (org-get-tags nil t)
            :props (delq nil (mapcar (lambda (k)
                                       (let ((v (org-entry-get nil k)))
                                         (and v (cons k v))))
                                     roam-ctx-triage-kept-properties))
            :file-to (org-entry-get nil "FILE_TO")
            :under (org-entry-get nil "FILE_UNDER")
            :body (string-trim (buffer-substring-no-properties (min body-beg end) end))
            :beg beg :end end))))

(defun roam-ctx-triage--shift-headings (text delta)
  "Change the level of every heading in TEXT by DELTA."
  (replace-regexp-in-string
   "^\\(\\*+\\) "
   (lambda (m) (concat (make-string (max 1 (+ (length (match-string 1 m)) delta)) ?*) " "))
   text t t))

(defun roam-ctx-triage--drawer (props &optional id)
  "Return a property drawer string for PROPS, with ID first when given."
  (concat ":PROPERTIES:\n"
          (when id (format ":ID:       %s\n" id))
          (mapconcat (lambda (p) (format ":%s: %s\n" (car p) (cdr p))) props "")
          ":END:\n"))

;;;; Locating a filing target

(defun roam-ctx-triage--split-path (path)
  "Split heading PATH (\"A > B\") into a list of titles."
  (and path (not (string-empty-p path)) (split-string path " > ")))

(defun roam-ctx-triage--goto-child (title)
  "Move from the heading at point (or file level, at bob) to child TITLE."
  (let* ((at-heading (org-at-heading-p))
         (level (if at-heading (1+ (org-current-level)) 1))
         (bound (if at-heading (save-excursion (org-end-of-subtree t t)) (point-max)))
         (re (format "^\\*\\{%d\\} " level))
         found)
    (save-excursion
      (when at-heading (forward-line 1))
      (while (and (not found) (re-search-forward re bound t))
        (beginning-of-line)
        (if (equal (org-get-heading t t t t) title)
            (setq found (point))
          (forward-line 1))))
    (unless found (user-error "No heading \"%s\" in target note" title))
    (goto-char found)))

(defun roam-ctx-triage--goto-target (node under)
  "Visit NODE's file and move to the heading at relative path UNDER.
Leave point at bob for a file-level target.  Return the target level."
  (let ((file (org-roam-node-file node)))
    (set-buffer (find-file-noselect file))
    (widen)
    (goto-char (if (zerop (org-roam-node-level node)) (point-min) (org-roam-node-point node)))
    (dolist (title (roam-ctx-triage--split-path under))
      (roam-ctx-triage--goto-child title))
    (if (org-at-heading-p) (org-current-level) 0)))

(defun roam-ctx-triage--outline (node)
  "Return heading paths below NODE, relative to it, as \"A > B\" strings."
  (with-current-buffer (find-file-noselect (org-roam-node-file node))
    (save-excursion
      (save-restriction
        (widen)
        (let* ((base (org-roam-node-level node))
               (paths '()) (stack '()))
          (if (zerop base)
              (goto-char (point-min))
            (goto-char (org-roam-node-point node))
            (org-narrow-to-subtree)
            (forward-line 1))
          (while (re-search-forward org-heading-regexp nil t)
            (let ((level (org-current-level)))
              (when (> level base)
                (setq stack (seq-filter (lambda (e) (< (car e) level)) stack))
                (push (cons level (org-get-heading t t t t)) stack)
                (push (mapconcat #'cdr (reverse stack) " > ") paths))))
          (nreverse paths))))))

;;;; Filing

(defun roam-ctx-triage--new-file-name (node)
  "Return a path in `org-roam-directory' for NODE, per the extract template."
  (let ((template (org-roam-format-template
                   (string-trim (org-capture-fill-template org-roam-extract-new-file-path))
                   (lambda (key default)
                     (let ((fn (intern (concat "org-roam-node-" key))))
                       (if (fboundp fn) (funcall fn node) (or default "")))))))
    (expand-file-name template org-roam-directory)))

(defun roam-ctx-triage--file-new (cap &optional title)
  "Write capture CAP as a new org-roam note, titled TITLE if given."
  (let* ((title (or title (plist-get cap :title)))
         (id (org-id-new))
         (path (roam-ctx-triage--new-file-name (org-roam-node-create :id id :title title)))
         (tags (plist-get cap :tags)))
    (when (file-exists-p path) (user-error "%s already exists" path))
    (with-current-buffer (find-file-noselect path)
      (insert (roam-ctx-triage--drawer (plist-get cap :props) id)
              "#+title: " title "\n"
              (if tags (format "#+filetags: :%s:\n" (string-join tags ":")) "")
              "\n"
              (roam-ctx-triage--shift-headings (plist-get cap :body) -1)
              "\n")
      (save-buffer)
      (kill-buffer))
    path))

(defun roam-ctx-triage--file-into (cap node under)
  "File capture CAP as a child of the heading at path UNDER in NODE."
  (save-current-buffer
    (let* ((level (1+ (roam-ctx-triage--goto-target node under)))
           (tags (remove roam-ctx-triage-share-tag (plist-get cap :tags))))
      (if (org-at-heading-p) (org-end-of-subtree t t) (goto-char (point-max)))
      (unless (bolp) (insert "\n"))
      (insert (make-string level ?*) " " (plist-get cap :title)
              (if tags (format " :%s:" (string-join tags ":")) "") "\n"
              (roam-ctx-triage--drawer (plist-get cap :props))
              (roam-ctx-triage--shift-headings (plist-get cap :body) (1- level))
              "\n")
      (save-buffer)
      (org-roam-node-file node))))

(defun roam-ctx-triage--remove (cap)
  "Delete capture CAP from the inbox buffer and save it."
  (let ((inhibit-read-only t))
    (widen)
    (delete-region (plist-get cap :beg) (plist-get cap :end))
    (save-buffer)))

(defun roam-ctx-triage-file-capture (target &optional under title)
  "File the capture at point into TARGET, then remove it from the inbox.
TARGET is \"new\" or a node id; UNDER is a heading path inside it; TITLE
overrides the title of a new note.  Return the file written."
  (let* ((cap (roam-ctx-triage--capture))
         (file (if (equal target "new")
                   (roam-ctx-triage--file-new cap title)
                 (let ((node (org-roam-node-from-id target)))
                   (unless node (user-error "No org-roam node with id %s" target))
                   (roam-ctx-triage--file-into cap node under)))))
    (roam-ctx-triage--remove cap)
    file))

(defun roam-ctx-triage-discard-capture ()
  "Move the capture at point to .discarded.org in the inbox directory."
  (let* ((cap (roam-ctx-triage--capture))
         (text (buffer-substring-no-properties (plist-get cap :beg) (plist-get cap :end))))
    (write-region (concat text (if (string-suffix-p "\n" text) "" "\n")) nil
                  (expand-file-name ".discarded.org" roam-ctx-triage-inbox-directory) t 'silent)
    (roam-ctx-triage--remove cap)))

;;;; Triage mode

(defun roam-ctx-triage--inbox-files ()
  "Return inbox files, oldest first."
  (let ((dir (expand-file-name roam-ctx-triage-inbox-directory)))
    (and (file-directory-p dir)
         (directory-files dir t "\\`[^.].*\\.org\\'"))))

(defun roam-ctx-triage--other-files ()
  "Return inbox files other than the current one, those after it first."
  (let* ((files (roam-ctx-triage--inbox-files))
         (tail (cdr (member buffer-file-name files))))
    (append tail (seq-difference files (cons buffer-file-name tail)))))

(defun roam-ctx-triage--describe-target (cap)
  "Return a short description of CAP's filing recommendation."
  (let ((to (plist-get cap :file-to)) (under (plist-get cap :under)))
    (cond ((or (null to) (equal to "new")) "new note")
          ((org-roam-node-from-id to)
           (concat (org-roam-node-title (org-roam-node-from-id to))
                   (if under (concat " › " under) "")))
          (t (format "missing node %s" to)))))

(defun roam-ctx-triage--show ()
  "Narrow to the capture at point and update the header line."
  (widen)
  (if (zerop (roam-ctx-triage--entries))
      (let ((status (roam-ctx-triage--next-file)))
        (when status (message "%s" status)))
    (unless (ignore-errors (roam-ctx-triage--goto-entry) t)
      (goto-char (point-min))
      (re-search-forward "^\\* ")
      (beginning-of-line))
    (let* ((cap (roam-ctx-triage--capture))
           (index (save-excursion
                    (let ((n 1) (here (point)))
                      (goto-char (point-min))
                      (while (and (re-search-forward "^\\* " nil t) (< (match-beginning 0) here))
                        (setq n (1+ n)))
                      n))))
      (org-narrow-to-subtree)
      (org-fold-show-subtree)
      (setq header-line-format
            (format " %d/%d%s  %s  →  %s    [f]ile [F]ile… [d]iscard [e]dit [n]ext [p]rev [q]uit"
                    index (roam-ctx-triage--entries)
                    (let ((n (length (roam-ctx-triage--other-files))))
                      (if (zerop n) "" (format " (+%d files)" n)))
                    (propertize (or (cdr (assoc "SUMMARY" (plist-get cap :props))) "")
                                'face 'bold)
                    (roam-ctx-triage--describe-target cap))))))

(defun roam-ctx-triage--next-file ()
  "Delete the current inbox file if empty and visit the next one.
Return a status message, or nil if another capture is now shown."
  (let ((next (car (roam-ctx-triage--other-files)))
        (empty (zerop (roam-ctx-triage--entries))))
    (when empty
      (let ((file buffer-file-name))
        (set-buffer-modified-p nil)
        (kill-buffer)
        (delete-file file)))
    (cond
     (next
      (find-file next)
      (roam-ctx-triage-mode 1)
      (goto-char (point-min))
      (roam-ctx-triage--show)
      nil)
     (empty "Inbox empty")
     (t "Last capture"))))

(defun roam-ctx-triage-next ()
  "Show the next capture."
  (interactive)
  (widen)
  (roam-ctx-triage--goto-entry)
  (if (save-excursion (org-end-of-subtree t t) (re-search-forward "^\\* " nil t))
      (progn (org-end-of-subtree t t) (roam-ctx-triage--show))
    (org-narrow-to-subtree)
    (let ((status (roam-ctx-triage--next-file)))
      (when status (message "%s" status)))))

(defun roam-ctx-triage-previous ()
  "Show the previous capture."
  (interactive)
  (widen)
  (roam-ctx-triage--goto-entry)
  (if (re-search-backward "^\\* " nil t)
      (roam-ctx-triage--show)
    (roam-ctx-triage--show)
    (message "First capture in this file")))

(defun roam-ctx-triage--after-action (msg)
  "Show the capture now at point, or move on, then report MSG."
  (let ((status (if (zerop (roam-ctx-triage--entries))
                    (roam-ctx-triage--next-file)
                  (when (eobp) (re-search-backward "^\\* " nil t))
                  (roam-ctx-triage--show)
                  nil)))
    (message "%s%s" msg (if status (concat ". " status) ""))))

(defun roam-ctx-triage-file ()
  "File the capture where the agent recommended."
  (interactive)
  (let* ((cap (roam-ctx-triage--capture))
         (file (roam-ctx-triage-file-capture (or (plist-get cap :file-to) "new")
                                             (plist-get cap :under))))
    (roam-ctx-triage--after-action (format "Filed to %s" (abbreviate-file-name file)))))

(defun roam-ctx-triage-file-elsewhere ()
  "File the capture into a note and heading chosen interactively.
Typing a title that matches no note creates a new note with that title."
  (interactive)
  (let* ((cap (roam-ctx-triage--capture))
         (node (org-roam-node-read (plist-get cap :title) nil nil nil "File to note: "))
         (file
          (if (org-roam-node-file node)
              (let* ((top "(top of note)")
                     (under (completing-read "Under heading: "
                                             (cons top (roam-ctx-triage--outline node))
                                             nil t nil nil top)))
                (roam-ctx-triage-file-capture (org-roam-node-id node)
                                              (unless (equal under top) under)))
            (roam-ctx-triage-file-capture "new" nil (org-roam-node-title node)))))
    (roam-ctx-triage--after-action (format "Filed to %s" (abbreviate-file-name file)))))

(defun roam-ctx-triage-discard ()
  "Discard the capture."
  (interactive)
  (roam-ctx-triage-discard-capture)
  (roam-ctx-triage--after-action "Discarded (kept in .discarded.org)"))

(defun roam-ctx-triage-edit ()
  "Edit the capture; \\[roam-ctx-triage-resume] resumes triage."
  (interactive)
  (roam-ctx-triage-mode -1)
  (roam-ctx-triage-edit-mode 1)
  (message "Editing; C-c C-c to resume triage"))

(defun roam-ctx-triage-resume ()
  "Save edits and resume triage."
  (interactive)
  (roam-ctx-triage-edit-mode -1)
  (save-buffer)
  (roam-ctx-triage-mode 1)
  (roam-ctx-triage--show))

(defun roam-ctx-triage-quit ()
  "Stop triage, leaving remaining captures in place."
  (interactive)
  (widen)
  (roam-ctx-triage-mode -1)
  (setq header-line-format nil)
  (bury-buffer))

(defvar roam-ctx-triage-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "f" #'roam-ctx-triage-file)
    (define-key map "F" #'roam-ctx-triage-file-elsewhere)
    (define-key map "d" #'roam-ctx-triage-discard)
    (define-key map "e" #'roam-ctx-triage-edit)
    (define-key map "n" #'roam-ctx-triage-next)
    (define-key map "p" #'roam-ctx-triage-previous)
    (define-key map "q" #'roam-ctx-triage-quit)
    map)
  "Keymap for `roam-ctx-triage-mode'.")

(define-minor-mode roam-ctx-triage-mode
  "Single-key triage of agent captures."
  :lighter " Triage"
  (setq-local make-backup-files nil)
  (setq buffer-read-only roam-ctx-triage-mode))

(defvar roam-ctx-triage-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'roam-ctx-triage-resume)
    map)
  "Keymap for `roam-ctx-triage-edit-mode'.")

(define-minor-mode roam-ctx-triage-edit-mode
  "Editing a capture during triage."
  :lighter " Triage:edit")

;;;###autoload
(defun roam-ctx-triage ()
  "Triage agent captures, oldest first."
  (interactive)
  (let ((files (roam-ctx-triage--inbox-files)))
    (if (null files)
        (message "Inbox empty")
      (find-file (car files))
      (roam-ctx-triage-mode 1)
      (goto-char (point-min))
      (roam-ctx-triage--show))))

(provide 'roam-ctx-triage)
;;; roam-ctx-triage.el ends here

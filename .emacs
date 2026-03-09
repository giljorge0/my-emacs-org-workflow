;;; -- lexical-binding: t --

;; 1. BASIC UI SETTINGS
(custom-set-variables
 '(cua-mode t)
 '(custom-enabled-themes '(modus-vivendi))
 '(menu-bar-mode nil)
 '(package-selected-packages nil)
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(tooltip-mode nil))

(custom-set-faces
 '(default ((t (:family "DejaVu Sans Mono"
                        :foundry "PfEd"
                        :slant normal
                        :weight regular
                        :height 151
                        :width normal)))))

;; 2. FILE AND DIRECTORY BEHAVIOR
(setq initial-buffer-choice "~/Nextcloud/brain/")
(setq dired-listing-switches "-lh --group-directories-first")
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(setq org-default-notes-file "~/Nextcloud/brain/random.org")

(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save/" t)))
(setq create-lockfiles nil)

;; 3. KEYBINDINGS
(global-set-key (kbd "C-s") 'isearch-forward)
(global-set-key (kbd "C-r") 'isearch-backward)
(global-set-key (kbd "C-c c") 'org-capture)
(global-set-key (kbd "<f5>") (lambda () (interactive)
                               (find-file "~/Nextcloud/brain/tasks.org")))
(global-set-key (kbd "<f6>") (lambda () (interactive)
                               (find-file "~/Nextcloud/brain/time.org")))

;; Junk File Cleaner
(defun clean-junk-files ()
  "Delete all hashtag and tilde files in the brain folder."
  (interactive)
  (shell-command "rm -f ~/Nextcloud/brain/#* ~/Nextcloud/brain/*~")
  (when (derived-mode-p 'dired-mode) (revert-buffer))
  (message "Junk cleared!"))

(global-set-key (kbd "<f12>") 'clean-junk-files)

;; 4. ORG MODE & TIME TRACKING
(with-eval-after-load 'org
  (setq org-startup-folded t)
  (setq org-clock-persist 'history)
  (when (fboundp 'org-clock-persistence-insinuate)
    (org-clock-persistence-insinuate))
  (remove-hook 'kill-emacs-query-functions 'org-clock-kill-emacs-query)
  (setq org-columns-default-format "%40ITEM(Activity) %15CLOCKSUM(Today) %10PERFORMANCE")
  (setq org-duration-format 'h:mm))

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c .") 'org-time-stamp)
(global-set-key (kbd "C-c C-x C-i") 'org-clock-in)
(global-set-key (kbd "C-c C-x C-o") 'org-clock-out)
(global-set-key (kbd "C-c C-x e") 'org-set-effort)

(setq org-todo-keywords
      '((sequence "TODO(t)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))

;; 5. CAPTURE TEMPLATES
(defun my/format-duration (secs)
  (let* ((total-min (floor (/ (float secs) 60.0)))
         (hours (/ total-min 60))
         (mins (mod total-min 60)))
    (format "%d:%02d" hours mins)))

(defun my/org-capture-sleep-string ()
  (let* ((sleep-str (org-read-date nil nil nil "Went to sleep (time):"))
         (wake-str (org-read-date nil nil nil "Woke up (time):"))
         (start-time (org-time-string-to-time sleep-str))
         (end-time (org-time-string-to-time wake-str))
         (secs (float-time (time-subtract end-time start-time)))
         (dur (my/format-duration (if (< secs 0) (* -1 secs) secs))))
    (format "- CLOCK: %s--%s => %s\n" sleep-str wake-str dur)))

(setq org-capture-templates
      '(("r" "Random Thought" entry
         (file+headline "~/Nextcloud/brain/random.org" "Inbox")
         "* %?\n %U")
        ("t" "Add Time (ACTIVITIES item)" item
         (file+headline "~/Nextcloud/brain/time.org" "ACTIVITIES")
         "- CLOCK: %^{Start Time}U--%^{End Time}U\n")
        ("S" "Sleep (compute duration)" item
         (file+headline "~/Nextcloud/brain/time.org" "ACTIVITIES")
         "%(my/org-capture-sleep-string)")))

;; 6. ARCHIVE LOCATION
;; keep coarse archive location variable if you want, but we will store
;; archived time/training files under ~/Nextcloud/memory/YYYY/MM/
(setq my/memory-base (expand-file-name "~/Nextcloud/memory/"))
(setq org-archive-location
      (expand-file-name (concat my/memory-base "%s_archive::")))

(setq org-agenda-files
      (directory-files-recursively
       (expand-file-name "~/Nextcloud/brain/") "\\.org$"))

;; 7. DAILY TIME RESET
(defun my/_ensure-memory-dir (year month)
  "Ensure memory directory for YEAR and MONTH exists and return it (with trailing slash)."
  (let ((dir (expand-file-name (format "%s%s/%s/" my/memory-base year month))))
    (unless (file-exists-p dir) (make-directory dir t))
    dir))

(defun my/daily-time-reset ()
  "If ~/Nextcloud/brain/time.org was last modified on a previous day, move it into
~/Nextcloud/memory/YYYY/MM/time-YYYY-MM-DD.org and create a fresh time.org."
  (let* ((time-file (expand-file-name "~/Nextcloud/brain/time.org"))
         (today (format-time-string "%Y-%m-%d")))
    (when (file-exists-p time-file)
      (let* ((last-mod (format-time-string "%Y-%m-%d"
                                          (file-attribute-modification-time
                                           (file-attributes time-file)))))
        (unless (string= last-mod today)
          ;; parse year and month from last-mod "YYYY-MM-DD"
          (let ((year (substring last-mod 0 4))
                (month (substring last-mod 5 7)))
            (let ((target-dir (my/_ensure-memory-dir year month))
                  (target-file (expand-file-name (format "time-%s.org" last-mod)
                                                 (my/_ensure-memory-dir year month))))
              ;; Move the file into memory/YYYY/MM/time-YYYY-MM-DD.org
              (rename-file time-file target-file 1)
              ;; Create a fresh time.org (in brain) with initial header
              (with-temp-file time-file
                (insert "* ACTIVITIES\n\n"))
              (message "Archived time.org -> %s and reset time.org" target-file))))))))

(add-hook 'after-init-hook 'my/daily-time-reset)

;; ======================================
;; MONTHLY TRAINING FILE AUTO-CREATION (now stored under YYYY/MM/)
;; ======================================

(require 'calendar)

(defun my/generate-month-days (year month)
  "Return a string with daily headings for YEAR (number) and MONTH (number)."
  (let* ((days (calendar-last-day-of-month month year))
         (output ""))
    (dotimes (d days)
      (setq output
            (concat output
                    (format "* %04d-%02d-%02d\n\n"
                            year month (1+ d)))))
    output))

(defun my/create-monthly-training-file ()
  "Create a training-YYYY-MM.org file under ~/Nextcloud/memory/YYYY/MM/ if it doesn't exist."
  (let* ((year (string-to-number (format-time-string "%Y")))
         (month (string-to-number (format-time-string "%m")))
         (year-str (format "%04d" year))
         (month-str (format "%02d" month))
         (dir (my/_ensure-memory-dir year-str month-str))
         (filename (format "training-%s-%s.org" year-str month-str))
         (filepath (expand-file-name filename dir)))
    (unless (file-exists-p filepath)
      (with-temp-file filepath
        (insert (format "#+title: Training Log %s-%s\n" year-str month-str))
        (insert "#+filetags: :training:\n")
        (insert "#+startup: folded\n\n")
        (insert (my/generate-month-days year month)))
      (message "Created monthly training file: %s" filepath))))

(add-hook 'after-init-hook #'my/create-monthly-training-file)

(defun my/open-current-training-file ()
  "Open the current month's training file stored in ~/Nextcloud/memory/YYYY/MM/."
  (interactive)
  (let* ((year (format-time-string "%Y"))
         (month (format-time-string "%m"))
         (filename (format "%straining-%s-%s.org" (my/_ensure-memory-dir year month) year month)))
    (find-file filename)))

(global-set-key (kbd "<f7>") #'my/open-current-training-file)

;; 8. REORGANIZER (one-shot) - move existing training/time files into YEAR/MM subdirs
(defun my/reorganize-memory-into-year-month ()
  "Move existing training-YYYY-MM.org and time-YYYY-MM-DD.org files under my/memory-base/YEAR/MM/.
This is safe: it only moves files that match the expected name patterns.
You will be prompted for confirmation."
  (interactive)
  (let* ((base my/memory-base)
         (all (directory-files base t nil))
         (candidates (cl-remove-if-not
                      (lambda (f)
                        (let ((name (file-name-nondirectory f)))
                          (or (string-match-p "^training-[0-9]\\{4\\}-[0-9]\\{2\\}\\.org$" name)
                              (string-match-p "^time-[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\.org$" name))))
                      all)))
    (if (null candidates)
        (message "No training/time files in %s to reorganize." base)
      (when (y-or-n-p (format "Move %d files into year/month subdirs under %s? " (length candidates) base))
        (dolist (f candidates)
          (let ((name (file-name-nondirectory f)))
            (cond
             ((string-match "^training-\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)\\.org$" name)
              (let ((y (match-string 1 name))
                    (m (match-string 2 name))
                    (dest-dir (my/_ensure-memory-dir (match-string 1 name) (match-string 2 name))))
                (let ((target (expand-file-name name dest-dir)))
                  (when (not (string= (file-truename f) (file-truename target)))
                    (rename-file f target 1)))))
             ((string-match "^time-\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\.org$" name)
              (let ((y (match-string 1 name))
                    (m (match-string 2 name))
                    (dest-dir (my/_ensure-memory-dir y m)))
                (let ((target (expand-file-name name dest-dir)))
                  (when (not (string= (file-truename f) (file-truename target)))
                    (rename-file f target 1))))))))
        (message "Reorganization complete.")))))

;; Bind reorganizer to C-c t m (you can run it manually)
(global-set-key (kbd "C-c t m") #'my/reorganize-memory-into-year-month)

;; 9. WINDOW BEHAVIOR
(setq pop-up-windows nil)
(add-to-list 'display-buffer-alist
             '(".*" (display-buffer-same-window) . nil))

;; 10. AUTO SAVE ON FOCUS OUT
(add-hook 'focus-out-hook 'save-some-buffers)


(require 'cl-lib)

(defun my/simple-reorganize-memory ()
  "Move all training-YYYY-MM.org and time-YYYY-MM-DD.org files
from ~/Nextcloud/memory/ into ~/Nextcloud/memory/YYYY/MM/.
Never deletes anything. Skips files if target already exists."
  (interactive)
  (let* ((base (expand-file-name "~/Nextcloud/memory/"))
         (files (directory-files base t "\\.org$"))
         moved skipped)
    (setq moved 0 skipped 0)
    (dolist (f files)
      (let ((name (file-name-nondirectory f)))
        (cond
         
         ;; training-YYYY-MM.org
         ((string-match "^training-\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)\\.org$" name)
          (let* ((year (match-string 1 name))
                 (month (match-string 2 name))
                 (dir (expand-file-name (format "%s/%s/" year month) base))
                 (target (expand-file-name name dir)))
            (unless (file-exists-p dir)
              (make-directory dir t))
            (if (file-exists-p target)
                (setq skipped (1+ skipped))
              (rename-file f target)
              (setq moved (1+ moved)))))

         ;; time-YYYY-MM-DD.org
         ((string-match "^time-\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\.org$" name)
          (let* ((year (match-string 1 name))
                 (month (match-string 2 name))
                 (dir (expand-file-name (format "%s/%s/" year month) base))
                 (target (expand-file-name name dir)))
            (unless (file-exists-p dir)
              (make-directory dir t))
            (if (file-exists-p target)
                (setq skipped (1+ skipped))
              (rename-file f target)
              (setq moved (1+ moved))))))))
    (message "Done. Moved: %d  Skipped (already existed): %d" moved skipped)))

(global-set-key (kbd "C-c r") #'my/simple-reorganize-memory)
;; END

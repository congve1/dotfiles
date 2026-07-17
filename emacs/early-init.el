;;; early-init.el --- earliest birds -*- lexical-binding:t;no-byte-compile:t; -*-
;;; Commentary:
;;; Code:

(setq package-user-dir
      (expand-file-name
       (format "elpa-%s"
               emacs-major-version)
       user-emacs-directory))

(require 'cl-lib)

(setq load-prefer-newer t)
(setq package-enable-at-startup nil)
;; 暂存 file-name-handler-alist 并在启动期间置空，减少启动期文件查找开销。
;; 在 init.el 的 emacs-startup-hook 中恢复（见 GC 配置部分）。
(defvar clw/init-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
;; `use-package' is builtin since 29.
;; It must be set before loading `use-package'.
(setq use-package-enable-imenu-support t)

;; Prevent unwanted runtime compilation for Emacs with native-comp
(setq native-comp-jit-compilation nil)

;; Suppress "Loading ...done" messages during startup
(setq inhibit-message-regexps '("^Loading "))
(setq set-message-functions '(inhibit-message))

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

;; Prevent the glimpse of un-styled Emacs by disabling these UI elements early
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(push '(fullscreen . maximized) initial-frame-alist)
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist))

(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))

;; Configure keys specific to macOS
(when (featurep 'ns)
  (setq ns-command-modifier 'meta)
  (setq ns-alternate-modifier 'super))

;;; Encoding
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8)
(setq system-time-locale "C")

;; Prevent flash of unstyled mode line
(setq-default mode-line-format nil)

(defvar clw/font-size (cond ((eq system-type 'darwin) 15)
                            ((eq system-type 'windows-nt) 13.5)
                            (t 17))
  "Current font size."
  )

(defvar clw/font-weight "regular"
  "Current font weight")

(defvar clw/fonts
  `((mono . "Maple Mono NF CN")
    (sans . "Maple Mono NF CN")
    (serif . "Maple Mono NF CN")
    (cjk . "Maple Mono NF CN")
    (symbol . "Segoe UI Emoji")
    )
  "Fonts to use")
(defun clw/get-font-family (key)
  "Get font family with key"
  (let ((font (alist-get key clw/fonts)))
    (if (string-empty-p font)
        (alist-get 'mono clw/fonts)
      font)))
(defun clw/load-default-font ()
  "Load default font configuration."
  (let ((default-font (format "%s-%s:%s"
                              (clw/get-font-family 'mono)
                              clw/font-size clw/font-weight)))
    (add-to-list 'default-frame-alist (cons 'font default-font))))

(defun clw/load-face-font ()
  "Load face font configuration."
  (let ((sans (format "%s-%s:%s" (clw/get-font-family 'sans)
                      clw/font-size clw/font-weight))
        (mono (format "%s-%s:%s" (clw/get-font-family 'mono)
                      clw/font-size clw/font-weight))
        (serif (format "%s-%s:%s" (clw/get-font-family 'serif)
                       clw/font-size clw/font-weight)))
    (set-face-attribute 'variable-pitch nil :font sans)
    (set-face-attribute 'variable-pitch-text nil :family serif)
    (set-face-attribute 'fixed-pitch nil :font mono)
    (set-face-attribute 'fixed-pitch-serif nil :font mono)
    (set-face-attribute 'mode-line-active nil :font sans)
    (set-face-attribute 'mode-line-inactive nil :font sans)))

(defun clw/load-charset-font (&optional font)
  "Load charset FONT configuration."
  (let ((default-font (or font (format "%s-%s:%s"
                                       (clw/get-font-family 'mono)
                                       clw/font-size clw/font-weight)))
        (cjk-font (clw/get-font-family 'cjk))
        (symbol-font (clw/get-font-family 'symbol))
        (scale-factor (if (eq system-type 'windows-nt) 1.1 1.2))
        )
    (set-frame-font default-font)
    ;;(add-to-list 'face-font-rescale-alist `(,cjk-font . ,scale-factor))
    (dolist (charset '(kana han hangul cjk-misc bopomofo))
      (set-fontset-font t charset cjk-font))
    (set-fontset-font t 'symbol symbol-font)
    (set-fontset-font t 'unicode symbol-font nil 'append)))


(clw/load-default-font)
;; Run after startup
(add-hook 'after-init-hook (lambda ()
                             (when (display-graphic-p)
                               (clw/load-face-font)
                               (clw/load-charset-font))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;early-init.el ends here

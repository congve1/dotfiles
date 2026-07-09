;;; init.el --- clw's emacs config -*- lexical-binding:t;no-byte-compile:t; -*-

;;; Code
;;@ 常量
(defconst clw-custom-example-file
  (expand-file-name "custom-example.el" user-emacs-directory)
  "Custom example file of Clw Emacs.")
(defconst sys/win32p
  (eq system-type 'windows-nt)
  "Are we running on a WinTel system?")

(defconst sys/linuxp
  (eq system-type 'gnu/linux)
  "Are we running on a GNU/Linux system?")

(defconst sys/macp
  (eq system-type 'darwin)
  "Are we running on a Mac system?")

(defun is-wsl-p ()
  "Return non-nil if running in WSL."
  (and (eq system-type 'gnu/linux)
       (file-readable-p "/proc/version")
       (let ((version (with-temp-buffer
                        (insert-file-contents "/proc/version")
                        (buffer-string))))
         ;; 不区分大小写匹配 "microsoft" 或 "WSL"
         (string-match-p "\\(microsoft\\|WSL\\)" version))))
;;@ 缓存 WSL 检测结果，避免每次读 /proc/version
(defconst sys/wslp (is-wsl-p) "Are we running in WSL?")
;;@ 辅助函数
(defun clw/load-theme (theme)
  "Disable others and enable NEW theme"
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t)
  )
;;@ 基础配置
;;@@ custom配置
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (and (not (file-exists-p custom-file))
           (file-exists-p clw-custom-example-file))
  ;; Copy template
  (copy-file clw-custom-example-file custom-file))
;;@@ 调整gc
;; 启动期间使用大阈值避免 GC 拖慢加载，启动完成后恢复为较小阈值，
;; 使运行期 GC 更频繁但每次耗时更短，编辑更流畅。
;; 参考: https://github.com/purcell/emacs.d/blob/master/init.el#L27
(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (setq gc-cons-percentage 0.5)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (garbage-collect)
              (setq gc-cons-threshold normal-gc-cons-threshold)
              (setq gc-cons-percentage 0.1)
              (when (boundp 'clw/init-file-name-handler-alist)
                (setq file-name-handler-alist
                      clw/init-file-name-handler-alist)))))
;;@@ emacs 版本必须大于等于 30.1
(when (version< emacs-version "30.1")
  (error "init.el: emacs version must >= 29.1"))
;;@@ Emacs 31 新特性，缓存 load-path 加快加载速度，大约提升 15%
;; (when (boundp 'load-path-filter-function)
;;   (setq load-path-filter-function #'load-path-filter-cache-directory-files))
;; 通过设定以下变量减小搜索项数量也能带来类似的提升，但在提交上述补丁后下面的选项
;; 没有太大的提升：https://emacs-china.org/t/windows-dev-drive-emacs/29362/22
(when nil
  (setq load-suffixes '(".elc" ".el"))
  (setq load-file-rep-suffixes '("")))

(when (boundp 'load-path-filter-function)
  (setq load-path-filter-function #'load-path-filter-cache-directory-files)
  (when (require 'persistent-cached-load-filter nil t)
    (persistent-cached-load-filter-easy-setup)))
;;@@ 定义用户的自定义 group，可以保存一些特定于机器的选项
;; 或者其他的一些选项。配置文件中出现的 option 默认属于该组，无需指定 `:group'
(defgroup clw nil
  "配置文件中的选项，可以用来保存一些特定于机器的路径或选项"
  :group 'emacs)
(defmacro clw/defcustom (symbol value doc &rest args)
  "保证使用 `clw/defcustom'定义的option位于`clw'组内"
  (declare (doc-string 3) (debug (name body))
           (indent defun))
  (let ((args (if (plist-get args :group) args
                (cons :group (cons ''clw args)))))
    `(defcustom ,symbol ,value ,doc ,@args))
  )
(defun clw/add-to-group (sym)
  "添加某一option到clw group中，方便显示"
  (custom-add-to-group 'clw sym 'custom-variable)
  )
(defun clw/customize ()
  (interactive)
  (customize-group 'clw))
;;@@ 定义一些custom变量
(clw/defcustom clw/use-pixel-scroll nil
  "是否使用像素滚动"
  :type 'boolean)

;;@@ 查看配置中需要手动配置的部分
(defun clw/occur-te ()
  "使用`occur' 列出配置文件中需要手动配置的位置 ;;te"
  (interactive)
  (with-current-buffer (get-file-buffer (expand-file-name "init.el" user-emacs-directory))
    (occur "^ *;;te"))
  )
;;@@ 设置 changelog file 相关的一些选项
(setopt add-log-full-name "congluwen")
(setopt add-log-mailing-address "congve1@live.com")
(setopt add-log-time-zone-rule t) ; 使用 UTC+0 时间
;;@@ 启动时不显示 GNU Emacs startup 页面
(setopt inhibit-startup-screen t)
(setopt initial-scratch-message (format ";;Emacs %s" emacs-version))
;;@@ 关闭 C-g, 边界移动命令响铃
(setopt ring-bell-function 'ignore)

;;@@ 不使用对话框
(setopt use-dialog-box nil)
;;@@ 基础补全设置
;; 按下 TAB 时进行补全，可设置为 'complete
;; 使用补全框架则不用设置
;; (setopt tab-always-indent 'complete)
;; 让 C-h f, C-h v 在选词阶段提供更多信息，更好看
(setopt completions-detailed t)
;; Emacs 29 提供了许多不错的补全改进
;; 但是，我们现在有超级好用的 vectico 了，不过加上也不费事
;; https://www.scss.tcd.ie/~sulimanm/posts/default-emacs-completion.html
;; https://robbmann.io/posts/emacs-29-completions/
(setopt completions-format 'one-column) ; 在补全 buffer 中单列显示候选词
(setopt completions-header-format nil)  ; 补全 buffer 中不显示汇总信息
(setopt completions-max-height 20)      ; 补全 buffer 限高为 20 行
(setopt completion-auto-select nil)     ; 触发补全时不移动焦点到补全 buffer
(setopt completion-styles '(flex))
;; 也许可以考虑试试 Protesilaos Stavrou 的时尚小垃圾 -- mct.el
;; https://protesilaos.com/emacs/mct
;;@@ 总是使用 y-or-n-p，可以少打字
;; 也可以设置 `use-short-answers' 为非空值
;; (defalias 'yes-or-no-p 'y-or-n-p)
(setopt use-short-answers t)
;;@@ backup 与 auto-save 设置
;; 不让 Emacs 生成 backup file，也就是 ~ 结尾的临时文件
(setopt make-backup-files nil)
;; 不进行 auto-save
(setopt auto-save-default nil)
;; 不创建 lock files
;; (info "(elisp) File Locks")
(setopt create-lockfiles nil)
;; 使用`save-some-buffers' 时默认保存所有文件
(defun clw/save-some-buffers ()
  "指定arg参数，保存时不弹出提示"
  (interactive)
  (save-some-buffers :clw/nowquery))
(bind-key "C-x s" #'clw/save-some-buffers)
;;@@ 设置默认的 major-mode 为 `text-mode'
(setq-default major-mode 'text-mode)
;;@@ 从子进程读取输出时的最大单次 thunk 读取字节数量，设置为 1MB
;; (setq process-adaptive-read-buffering nil)
(setq read-process-output-max (* 4 1024 1024))
;;@@ 单次滚动设置为 1 行
(setopt scroll-step 1)
(setopt scroll-conservatively 10000)
;;@@ 添加一些全局绑定
(bind-keys
 ;; 正则向前和向后搜索的快捷键
 ;; 使用 consult 爽一点
 ;;("C-c s" . isearch-forward-regexp)
 ;;("C-c r" . isearch-backward-regexp)
 ;; 不询问直接杀死 buffer
 ("C-x k" . kill-current-buffer)
 
 ;; 防止误触
 ("C-c <f12>" . save-buffers-kill-emacs)
 ;; 中文输入法下的处理，不用切换输入法了
 ("C-x 【" . backward-page)
 ("C-x 】" . forward-page)
 
 ("M-ｘ" . execute-extended-command)
 ("C-x ｂ" . switch-to-buffer)
 )
;;@@ 在关闭关联进程的 buffer 时不提示是否关闭
(setq kill-buffer-query-functions
      (remq 'process-kill-buffer-query-function
            kill-buffer-query-functions))

;;@@ 长行优化，以及一些显示效果优化
;; https://emacs.stackexchange.com/questions/598/how-do-i-prevent-extremely-long-lines-making-emacs-slow
(setq-default bidi-display-reordering 'left-to-right)
(setq-default bidi-paragraph-direction 'left-to-right)
(setq-default bidi-inhibit-bpa t)
(setq-default cursor-in-non-selected-windows nil)
(setopt fast-but-imprecise-scrolling t)
(global-so-long-mode 1)
;;@@ 让 so-long 在长行文件中也禁用我们通过 prog-mode-hook 加的 heavy minor-mode
(with-eval-after-load 'so-long
  (dolist (mode '(puni-mode symbol-overlay-mode treesit-auto-mode
                            corfu-mode apheleia-mode
                            display-fill-column-indicator-mode))
    (add-to-list 'so-long-minor-modes mode)))
;;@@ kill 时若与 kill-ring 内最后内容重复则不添加入 kill-ring
(setopt kill-do-not-save-duplicates t)

;;@@ 将大文件警告提升至大约 100MB
(setopt large-file-warning-threshold (* 100 1024 1024))

;;@@ 禁止光标移动到 minibuffer 的 prompt
(setopt minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
;;@@ 默认 80 的 fill-column
(setopt fill-column 80)

;;@@ 解锁一些被禁用的命令
(put 'list-timers 'disabled nil)
(put 'set-goal-column 'disabled nil)
(put 'erase-buffer 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)

;;@@ Windows 相关配置
(when sys/win32p
  ;; 为 Windows 添加 Super 和 Hyper 按键
  ;;(setq w32-pass-lwindow-to-system nil)
  ;;(setq w32-lwindow-modifier 'hyper)
  ;;(setq w32-pass-rwindow-to-system nil)
  ;;(setq w32-rwindow-modifier 'super)
  (setq w32-apps-modifier 'hyper)
  ;; 默认的 4KB 管道 buffer 太小了点，给到 64KB
  (setq w32-pipe-buffer-size (* 64 1024))
  ;; 在 Windows 下删除文件时默认移动到垃圾箱/回收站
  (setopt delete-by-moving-to-trash t)
  ;; 在 Windows 上没必要搜索两遍 auto-mode-alist，
  ;; 因为 Windows 文件系统忽略大小写
  (setopt auto-mode-case-fold nil)
  ;; tooltip-mode 在 Windows 下似乎有点卡
  (tooltip-mode -1))

;;@@ LINUX 额外的执行路径，（如果没有添加到 $PATH 的话）
;; 添加 ~/.local/bin 到 exe-path
(when sys/linuxp
  (add-to-list 'exec-path (expand-file-name "~/.local/bin")))

;;@@ clash
;; 辅助函数，获取网关地址，方便wsl使用
(defun clw/get-default-gateway (&optional fallback)
  "Get default gateway IP.
If not in WSL, return FALLBACK (default '127.0.0.1').
If in WSL, try to get gateway via system commands."
  (let ((fallback (or fallback "127.0.0.1")))
    ;; 非 WSL 环境：直接返回 fallback
    (if (not sys/wslp)
        fallback
      ;; WSL 环境：尝试获取网关
      (let ((gw nil))
        ;; 方法 1: 使用 ip route
        (when (and (null gw) (executable-find "ip"))
          (let ((output (shell-command-to-string "ip route show default 2>/dev/null")))
            (when (and (stringp output)
                       (string-match "via \\([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\)" output))
              (setq gw (match-string 1 output)))))
        
        ;; 方法 2: 使用 netstat
        (when (and (null gw) (executable-find "netstat"))
          (let ((output (shell-command-to-string "netstat -rn 2>/dev/null")))
            (dolist (line (split-string output "\n"))
              (when (and (string-match "^0\\.0\\.0\\.0" line)
                         (string-match "\\([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\)$" line))
                (setq gw (match-string 1 line))
                (return)))))
        
        ;; 返回网关或默认值
        (or gw fallback)))))

(defvar clw/proxy-enabled nil
  "是否已启用 clash(7897) 代理环境变量。默认不开启，用 `clw/proxy-toggle' 手动开关。")

(defun clw/proxy-toggle ()
  "切换 clash(7897) 代理环境变量的开启/关闭。
开启时用 `clw/get-default-gateway' 获取网关地址，设置 HTTP_PROXY/HTTPS_PROXY
及 `url-proxy-services'；关闭时清空这些变量。
需自行确保 clash 已在运行（监听 7897）。"
  (interactive)
  (let* ((gateway (clw/get-default-gateway))
         (proxy (format "%s:7897" gateway)))
    (if clw/proxy-enabled
        (progn
          (dolist (var '("HTTP_PROXY" "HTTPS_PROXY" "http_proxy" "https_proxy"))
            (setenv var nil))
          (setq url-proxy-services nil)
          (setq clw/proxy-enabled nil)
          (message "代理已关闭"))
      (dolist (var '("HTTP_PROXY" "HTTPS_PROXY" "http_proxy" "https_proxy"))
        (setenv var (format "http://%s" proxy)))
      (setq url-proxy-services
            `(("http" . ,proxy)
              ("https" . ,proxy)))
      (setq clw/proxy-enabled t)
      (message "代理已开启: http://%s" proxy))))
;;@@ IGC-IDLE-TIMER
;; 在 Emacs 空闲时 GC
(when (fboundp #'igc-collect)
  (igc-start-idle-timer))
;;@@ 鼠标滚动时保持光标在屏幕中的相对位置
;; https://lists.gnu.org/archive/html/emacs-devel/2025-12/msg00327.html
(setopt scroll-preserve-screen-position t)
;;@@ C-h f 需要按Enter，直接一步到位
(defalias 'clw/find-symbol-at-point
  (kmacro "C-h o <return>"))
(keymap-set emacs-lisp-mode-map "C-h y" 'clw/find-symbol-at-point)
(keymap-set lisp-interaction-mode-map "C-h y" 'clw/find-symbol-at-point)
;;@@ 关闭 `indent-tabs-mode'
(setopt indent-tabs-mode nil)
;;@@ 设置窗口整体透明度为 0.65
;; 当前 Windows 还未实现背景透明 [2025-09-15]
(defun clw/toggle-alpha ()
  (interactive)
  (if (eql (frame-parameter nil 'alpha) 1.0)
      (set-frame-parameter nil 'alpha 0.65)
    (set-frame-parameter nil 'alpha 1.0)))
(keymap-global-set "<f9>" 'clw/toggle-alpha)
;;@2 内置的 emacs 包
;;@@PACKAGE
;; 设置包源
(setopt package-archives
        '(("melpa" . "https://melpa.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")
          ("gnu" . "https://elpa.gnu.org/packages/")))
;; 不检查签名
(setopt package-check-signature nil)
(setopt package-archive-priorities
        '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))
;;@@ use-package
(setq use-package-enable-imenu-support t)
(setq use-package-expand-minimally t)
;; 关闭 use-package 统计以减少加载开销；分析启动耗时可临时设为 t
(setq use-package-compute-statistics nil)
;; Initialize packages
(unless (bound-and-true-p package--initialized) ; To avoid warnings in 27
  (setq package-enable-at-startup nil)          ; To prevent initializing twice
  (package-initialize))
(require  'use-package)
;;@@DIMINISH 放在最前面
;; 可以用来取消某些 minor-mode 字符在 modeline 的显示
(use-package diminish :ensure t :pin "gnu")
;;@@DISPLAY-LINE-NUMBERS 显示行号
(setopt line-number-display-limit
        (* 1024 1024))
;;(setq line-number-display-limit-width 1000)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
;;@@HL-LINE-MODE 高亮当前行
(add-hook 'prog-mode-hook 'hl-line-mode)
;;@@ELEC-PAIR 括号匹配高亮
(add-hook 'prog-mode-hook 'electric-pair-mode)
;;@@ ELEC_INDENT
(use-package elec-pair
  :config (electric-indent-mode))
;;@@DELETE-SELECTION-MODE 在选中区域时输入内容将删除区域
(delete-selection-mode t)
;;@@ compile
(use-package compile
  :bind
  ([f5] . compile)
  ([f6] . recompile)
  :custom (compilation-scroll-output 'first-error))
;;@@ eshell
(use-package eshell
  :custom (eshell-scroll-show-maximum-output nil))
;;@@UNIQUIFY 路径名显示唯一化
(setopt uniquify-buffer-name-style 'reverse
        uniquify-separator " ← "
        uniquify-ignore-buffers-re "^\\*")
;;@@ISEARCH “智能搜索”
(setopt isearch-allow-scroll t)
;;@@IBUFFER 高级 buffer 列表
(use-package ibuffer
  :bind ("C-x C-b" . clw/ibuffer)
  :config
  (defun clw/ibuffer ()
    (interactive)
    (if (string= (buffer-name) "*Ibuffer*")
        (ibuffer-update nil t)
      (ibuffer)))
  ;; 不显示临时 BUFFER
  ;; 还是显示吧
  ;;(setopt ibuffer-never-show-predicates '("^\\*"))
  ;; 在其他窗口中显示 ibuffer
  (setopt ibuffer-use-other-window t)
  ;; 不显示为空的分组
  (setopt ibuffer-show-empty-filter-groups nil)
  ;; 不显示汇总信息
  (setopt ibuffer-display-summary nil)
  ;; 显式人类可读的文件大小（Emacs 31 开始支持）
  (setopt ibuffer-human-readable-size t)
  ;; 默认的 filter-group
  (setopt ibuffer-saved-filter-groups
          '(("default"
             ("PROJECT"
              (name . "\\*<p>.+\\*"))
             ("emacs-src-el"
              (and (file-extension . "el")
                   (directory . "share/emacs/.*/lisp")))
             ("emacs-lisp"
              (or (file-extension . "el")
                  (mode . emacs-lisp-mode)))
             ("common-lisp"
              (or (file-extension . "lisp")
                  (mode . lisp-mode)))
             ("scheme/racket"
              (or (mode . scheme-mode)
                  (file-extension . "scm")))
             ("C/C++"
              (or (mode . c-mode)
                  (mode . c++-mode)
                  (filename . ".+\\.\\(c\\|cc\\|cpp\\|h\\|hpp\\)$")))
             ("Python"
              (or (mode . python-mode)
                  (mode . python-ts-mode)
                  (file-extension . "py")))
             ("js/css/html"
              (or (mode . js-mode)
                  (mode . js-ts-mode)
                  (mode . json-ts-mode)
                  (filename . ".+\\.\\(cjs\\|mjs\\|js\\|json\\|ts\\)")
                  (mode . html-mode)
                  (mode . css-mode)
                  (filename . ".+\\.wgsl")
                  (filename . ".+\\.html?")
                  (filename . ".+\\.css")))
             ("Rust"
              (or (mode . rust-ts-mode)
                  (file-extension . "rs")))
             ("rescript"
              (or (mode . rescript-mode)
                  (filename . ".+\\.resi?")))
             ("ORG"
              (or (mode . org-mode)
                  (file-extension . "org")))
             ("DIRED"
              (mode . dired-mode))
             ("IMAGES"
              (or (mode . image-mode)
                  (filename . ".+\\.\\(jpe?g\\|png\\|gif\\|webp\\|ppm\\|pgm\\|pbm\\)")))
             ("TEXT"
              (or (mode . text-mode)
                  (filename . ".+\\.txt")))
             ("CONFIG"
              (or (mode . conf-mode)
                  (filename . ".+\\.toml")
                  (filename . ".+\\.yaml")))
             ("LOG"
              (or (filename . "[cC][hH][aA][nN][gG][eE][lL][oO][gG]")
                  (mode . change-log-mode)))
             ("SHELL"
              (mode . shell-mode))
             ("HELP"
              (or (mode . help-mode)
                  (mode . Info-mode)
                  (mode . apropos-mode)))
             ("MAGIT"
              (or (mode . magit-status-mode)
                  (mode . magit-diff-mode)
                  (mode . magit-log-mode)))
             ("PROCESS"
              (process))
             ("TEMP"
              (name . "\\*.*\\*")))))
  (defun clw/ibuffer-use-default-group ()
    (and (not ibuffer-filter-groups) ;; not use group
         (assoc "default" ibuffer-saved-filter-groups)
         (ibuffer-switch-to-saved-filter-groups "default")))
  (add-hook 'ibuffer-hook 'clw/ibuffer-use-default-group))
;;@@AUTO-SAVE-VISITED-MODE 自动保存文件
;; Lazycat 写过一个叫 auto-save 的插件来在编辑文件后立刻保存
;; inlucde-yy在它的插件的基础上稍作改进过：
;; https://github.com/manateelazycat/auto-save
;; https://github.com/include-yy/tetosave
;; Emacs 26 支持一个叫做 `auto-save-visited-mode' 的 minor-mode
;; 在功能上和 auto-save 或 tetosave 一致，故直接使用内置 mode
(auto-save-visited-mode t)
;; 60s 保存一次，默认值是 5
(setopt auto-save-visited-interval 60)
;; 允许其他插件的配置添加自己的逻辑到 buffer 保存中来
(defvar clw/auto-save-visited-disable-predicates nil
  "谓词函数列表，当存在谓词返回 t 时，则不保存。")
(defun clw/auto-save-visited-savep ()
  "绑定于 `auto-save-visited-predicate' 的函数。

当 `clw/auto-save-visited-disable-predicates' 中的某个谓词函数返回 t
时，该函数返回 nil。这说明某个 buffer 不应该被保存。"
  (not (seq-some (lambda (p) (funcall p))
                 clw/auto-save-visited-disable-predicates)))
(setopt auto-save-visited-predicate
        #'clw/auto-save-visited-savep)
;; 来自 tetosave 中的一些判断谓词，可能有用
(defun clw/auto-save-visited-pred-org-capture ()
  "检查当前 buffer 是否存在 CAPTURE buffer。

当使用 org-capture 时，由于它使用了 indirect buffer 来在 buffer
中添加新的实体，CAPTURE buffer 的 `buffer-file-name' 为 `nil' 不会
被保存，但是捕获的目的 buffer 会被自动保存。通过检查 buffer 是否存在
带有 CAPTURE- 前缀的同名 buffer 来判断是否正处于 CAPTURE 状态。"
  (eq (buffer-base-buffer
       (get-buffer (concat "CAPTURE-" (buffer-name))))
      (current-buffer)))
(defun clw/auto-save-visited-pred-corfu ()
  "检查当前 buffer 是否正在用 corfu，避免保存打断补全。"
  (and (boundp 'corfu--total)
       (not (zerop corfu--total))))
(defun clw/auto-save-visited-pred-company ()
  "检查当前 buffer 是否正在用 company，避免保存打断补全。"
  (bound-and-true-p company-candidates))
(defun clw/other-disabled-predicates ()
  (and (not (buffer-live-p (get-buffer " *vundo tree*")))
       (not (string-suffix-p "gpg" (file-name-extension (buffer-name)) t))
       (not (eq (buffer-base-buffer
                 (get-buffer (concat "CAPTURE-" (buffer-name))))
                (current-buffer)))
       (or (not (boundp 'corfu--total)) (zerop corfu--total))
       (or (not (boundp 'yas--active-snippets))
           (not yas--active-snippets))))
;; 不过当时间间隔足够大时似乎不需要担心补全的问题。
(setq clw/auto-save-visited-disable-predicates
      (list #'clw/auto-save-visited-pred-org-capture
            #'clw/auto-save-visited-pred-corfu
            #'clw/auto-save-visited-pred-company
            #'clw/other-disabled-predicates))
;;@@RECENTF 保留最近文件打开记录
(use-package recentf
  :bind (("C-c r" . recentf-open))
  :init
  ;; 可在 `recentf-open-files' 中显示的最大文件数量
  (setopt recentf-max-menu-items 50)
  ;; recentf 保存的文件数量
  (setopt recentf-max-saved-items 2000)
  ;; 不进行保存文件的自动清理（避免启动时对 2000 条逐个 stat，改手动/空闲清理）
  (setopt recentf-auto-cleanup 'never)
  :config
  (recentf-mode 1)
  ;; 启动时显示 recentf buffer
  ;;(setopt initial-buffer-choice 'recentf-open-files)
  ;; 每三小时保存一次最近文件列表
  (defvar clw/recentf-save-timer nil)
  (unless clw/recentf-save-timer
    (setq clw/recentf-save-timer
          (run-at-time nil (* 2 60 60) 'recentf-save-list)))
  )
;;@@SAVEPLACE 关闭 buffer 时保存光标位置
;; 和 recentf-mode 联动一下，可以保存最近打开文件在关闭时的 point 位置
(save-place-mode 1)
;;@@WINNER 保留窗口配置记录，可回退和前进
(use-package winner
  :config
  (winner-mode 1)
  ;; 给快捷键添加 repeat-mode 支持
  (defvar clw/winner-repear-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "<up>") 'winner-undo)
      (define-key map (kbd "<down>") 'winner-redo)
      map))
  (dolist (cmd '(winner-undo winner-redo))
    (put cmd 'repeat-map 'clw/winner-repear-map))
  :bind (("C-x <up>" . winner-undo)
         ("C-x <down>" . winner-redo)))
;;@@ORG org-mode 基础配置
(use-package org
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture)
	 ("C-\\" . clw/insert-zws))
  :config
  (setopt org-tags-column 0)
  (setopt org-startup-truncated nil)
  (setopt org-image-actual-width 400)
  (setopt org-element-cache-persistent nil)
  (setopt org-export-dispatch-use-expert-ui t)
  (setq org-babel-default-header-args:elisp '((:lexical . "yes")))
  (add-hook 'org-mode-hook 'visual-line-mode)
  (add-hook 'org-mode-hook
   	    (defalias 'clw/disable-show-paren
   	      (lambda () (show-paren-local-mode -1))))
  (defun clw/insert-zws () (interactive) (insert "​"))
  ;; 启用 `completion-preview-mode'
  ;; https://www.reddit.com/r/emacs/comments/1j0wonk/how_to_trigger_completionpreview_in_orgmode_to/
  (add-hook
   'org-mode-hook
   (defun clw/set-completion-preview ()
     (completion-preview-mode)
     (let ((kmap (make-sparse-keymap)))
       (keymap-set kmap "C-i" #'completion-preview-insert)
       (keymap-set kmap "M-i" #'completion-preview-complete)
       (keymap-set kmap "C-n" #'completion-preview-next-candidate)
       (keymap-set kmap "C-p" #'completion-preview-prev-candidate)
       (keymap-set kmap "SPC" #'completion-preview-insert-word)
       (setq-local completion-preview-active-mode-map kmap))
     (setq-local completion-preview-commands
                 '(;; self-insert-command
                   org-self-insert-command
                   insert-char
                   ;; delete-backward-char
                   org-delete-backward-char
                   backward-delete-char-untabify
                   analyze-text-conversion
                   completion-preview-complete))))
  )
;;@@CC-MODE C 系语言基础配置
(use-package cc-mode
  :defer t
  :config
  (setq-default c-default-style
                '((c-mode . "gnu")
                  (java-mode . "java")
                  (awk-mode . "awk")
                  (other . "gnu")))
  (setq-default c-recognize-knr-p nil)
  ;;(setq c-basic-offset 4)
  (setopt c-electric-pound-behavior '(alignleft)))
;;@@ HIPPIE 方便的路径补全
(use-package hippie-exp
  :bind ([remap dabbrev-expand] . hippie-expand)
  :custom (hippie-expand-try-functions-list
           '(try-complete-file-name-partially
             try-complete-file-name
             try-expand-dabbrev
             try-expand-dabbrev-all-buffers
             try-expand-dabbrev-from-kill)))
;;@@ TREESIT 基于语法树的 PL 前端工具
(use-package treesit
  :when (and (fboundp 'treesit-available-p)
             (treesit-available-p))
  :custom
  (major-mode-remap-alist
   '((c-mode          . c-ts-mode)
     (go-mode         . go-ts-mode)
     (c++-mode        . c++-ts-mode)
     (csharp-mode     . csharp-ts-mode)
     (conf-toml-mode  . toml-ts-mode)
     (css-mode        . css-ts-mode)
     (java-mode       . java-ts-mode)
     (javascript-mode . js-ts-mode)
     (js-json-mode    . json-ts-mode)
     (python-mode     . python-ts-mode)
     (ruby-mode       . ruby-ts-mode)
     (rust-mode       . rust-ts-mode)))
  (c-ts-mode-indent-style 'linux)
  (c-ts-mode-indent-offset 8)
  :config
  (add-to-list 'auto-mode-alist
               '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode)))

;;@@ PIXEL-SCROLL
(when clw/use-pixel-scroll
  (use-package pixel-scroll
    :config
    (pixel-scroll-precision-mode 1)
    (setq pixel-scroll-precision-interpolate-page t)
    (defun clw/pixel-scroll-interpolate-down (&optional lines)
      (interactive)
      (if lines
          (pixel-scroll-precision-interpolate (* -1 lines (pixel-line-height)))
        (pixel-scroll-interpolate-down)))
    (defun clw/pixel-scroll-interpolate-up (&optional lines)
      (interactive)
      (if lines
          (pixel-scroll-precision-interpolate (* lines (pixel-line-height))))
      (pixel-scroll-interpolate-up))

    (defalias 'scroll-up-command 'clw/pixel-scroll-interpolate-down)
    (defalias 'scroll-down-command 'clw/pixel-scroll-interpolate-up)))
;;@@REPEAT-MODE 反复触发一组命令
;; 重复按键可以使用某个键反复触发，比如 C-x o o o ...
;; 可通过 `describe-repeat-maps' 来了解哪些命令可用
(repeat-mode 1)
;;@@ELDOC echo area 位置的短文档
(use-package eldoc
  :custom (eldoc-documentation-strategy #'eldoc-documentation-compose)
  :config
  (eldoc-add-command-completions "paredit-")
  ;; 0.5s 平衡响应与多源 compose 策略的 idle 开销
  (setopt eldoc-idle-delay 0.5)
  )


;;@@PROJECT 配置项目管理功能
(use-package project
  :bind ("C-x p C-b" . yy/project-list-buffers)
  :config
  ;; 使用 ibuffer 显示属于当前项目的文件
  ;; 可通过 `g' 键更新 ibuffer
  (defun yy/project-list-buffers (&optional arg)
    (interactive "P")
    (let* ((pr (project-current t))
           (root (expand-file-name (project-root pr)))
           (name (format "*<p>%s*"
                         (file-name-nondirectory
                          (directory-file-name root)))))
      (ibuffer t name)
      (ibuffer-filter-disable)
      (ibuffer-filter-by-filename root))))
;;@@AUTO-REVERT-MODE 当文件在外部被修改时，自动更新对应的 buffer
;; 轮询间隔翻倍；有 file-notify 时不再轮询（注意：drvfs 等 notify 不可靠的
;; 文件系统上将不自动 revert，需手动 M-x revert-buffer）
(setopt auto-revert-interval 10)
(setopt auto-revert-avoid-polling t)
(global-auto-revert-mode)
;;@@FILESETS 可用于保存一系列常用的文件，方便打开
;;te 添加一组自己常用的文件来让 emacs 启动时自动打开
;; 使用 `filesets-add-buffer' 添加 buffer 到 group 中
;; 使用 `filesets-edit' 来编辑 filesets group
(use-package filesets
  :disabled
  :config
  ;;(filesets-init)
  ;; 默认在启动时打开的一组 buffer，它们一般平时很有用
  (when (filesets-get-fileset-from-name "FREQ")
    (with-eval-after-load 'init
      (filesets-open nil "FREQ"))))
;;@@WINDMOVE 提供根据位置在 window 间移动 point 的方法
(use-package windmove
  :init
  (setopt windmove-wrap-around t)
  :config
  (windmove-mode t)
  ;; 使用 Hyper + wasd 在窗口间移动光标
  ;;(windmove-default-keybindings 'hyper)
  :bind (("H-a" . windmove-left)
         ("H-d" . windmove-right)
         ("H-w" . windmove-up)
         ("H-s" . windmove-down)))
;;@@SAVEHIST-MODE 保存 minibuffer 的 s 表达式求值历史
(savehist-mode t)
;;@@PRETTIFY-SYMBOLS-MODE 优化某些符号的显示
;; 全局打开
(global-prettify-symbols-mode)
;; 光标停在 prettify 符号上时不再取消 prettify，减少光标移动的 redisplay 开销
(setq prettify-symbols-un-prettify-at-point nil)
(add-hook 'emacs-lisp-mode-hook
          (defun clw/nouse-prettify ()
            (prettify-symbols-mode -1)))
;;@@ flymake
(use-package flymake
  :hook (prog-mode . flymake-mode)
  :hook (flymake-mode . (lambda ()
                          (setq eldoc-documentation-functions
                                (cons 'flymake-eldoc-function
                                      (delq 'flymake-eldoc-function
                                            eldoc-documentation-functions)))))
  :init (setq elisp-flymake-byte-compile-load-path (cons "./" load-path)))
;;@@EGLOT
;; 加载 eglot
(use-package eglot
  :defer t
  :hook ((python-base-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure))
  :bind (:map eglot-mode-map
         ("C-c l a" . eglot-code-actions)
         ("C-c l r" . eglot-rename)
         ("C-c l f" . eglot-format)
         ("C-c l d" . eldoc))
  :custom
  (eglot-report-progress nil)
  (eglot-autoshutdown t)
  (eglot-code-action-indicator "✓")
  (eglot-code-action-indications '(eldoc-hint mode-line))
  :config
  (add-to-list 'eglot-ignored-server-capabilities
               :documentHighlightProvider)
  (add-to-list 'eglot-ignored-server-capabilities
               :inlayHintProvider)
  (add-to-list 'eglot-ignored-server-capabilities
               :textDocument/hover)
  ;; 取消 eglot 的 log 消息，我不是 LSP server 的开发者
  (setopt eglot-events-buffer-size 0)
  ;; 在 mode-line 显示 action 操作。不然可能干扰 eldoc。Emacs 31
  (setopt eglot-code-action-indications '(mode-line))
  ;; 关掉 flymake 的一些提示信息，太吵了
  (add-to-list 'eglot-stay-out-of 'flymake)
  ;; 固定 python 用 basedpyright（环境里同时装了 ruff，避免每次二选一）
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio")))
  )
;;@@PYTHON Python 开发环境
(use-package python
  :defer t
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3")
  (python-shell-completion-native-enable nil)
  (python-shell-completion-native-disabled-interpreters
   '("pypy" "ipython3" "jupyter" "python3"))
  :config
  ;; 填充列与 Black/Ruff 默认值一致
  (add-hook 'python-base-mode-hook
            (lambda () (setq-local fill-column 88)))
  ;;@@ 自动检测 uv 项目的 .venv，让 REPL/LSP/formatter 都用项目虚拟环境
  ;; uv venv 默认在项目根创建 .venv；检测到就让 `run-python'、apheleia 的
  ;; ruff/black、eglot 的 pyright/pylsp 都对齐到项目 venv 的解释器与工具链。
  ;; 非 uv 项目（无 .venv）回落到上面 :custom 设的全局 python3。
  (defun clw/python-activate-uv-venv ()
    "若项目根存在 .venv，切换 python-shell 到该虚拟环境并扩展 exec-path。"
    (when-let* ((root (locate-dominating-file default-directory ".venv"))
                (venv (expand-file-name ".venv" root))
                (venv-bin (expand-file-name "bin" venv))
                (venv-python (expand-file-name "python" venv-bin)))
      (when (file-executable-p venv-python)
        (setq-local python-shell-interpreter venv-python)
        (setq-local python-shell-virtualenv-root venv)
        (setq-local exec-path (cons venv-bin exec-path))
        (setq-local process-environment
                    (append (list (concat "VIRTUAL_ENV=" venv)
                                  (concat "PATH=" venv-bin
                                          path-separator (getenv "PATH")))
                            process-environment)))))
  ;; depth 设负值，确保在 eglot-ensure(默认 depth 0) 之前执行，
  ;; 这样 eglot 首次启动 pyright/pylsp 时 process-environment 已就绪。
  (add-hook 'python-base-mode-hook #'clw/python-activate-uv-venv -90))

;;@@RUST Rust 开发环境
(use-package rust-ts-mode
  :custom
  ;; 缩进与 rustfmt 默认值一致（4 空格）
  (rust-ts-indent-offset 4)
  :config
  ;; 填充列与 rustfmt 默认值一致
  (add-hook 'rust-ts-mode-hook
            (lambda () (setq-local fill-column 100))))

;;@@GO Go 开发环境
(use-package go-ts-mode
  :config
  (require 'cl-lib)
  ;; Go 强制使用 tab 缩进（gofmt 要求），覆盖全局的 indent-tabs-mode。
  ;; tab 显示宽 4 列、每级缩进 1 个 tab（= 4 列）。tab-width 必须等于
  ;; go-ts-mode-indent-offset，否则会产生 tab+空格混合（gofmt 不接受）。
  ;; 文件内容仍是 tab，仅视觉宽度 4，不影响 gofmt 合规性。
  (add-hook 'go-ts-mode-hook
            (lambda ()
              (setq-local indent-tabs-mode t)
              (setq-local tab-width 4)
              (setq-local go-ts-mode-indent-offset 4)))
  ;; 填充列（go 注释行宽与 lll linter 习惯用 100）
  (add-hook 'go-ts-mode-hook
            (lambda () (setq-local fill-column 100)))
  ;;@@ 常用 Go 工具清单及一键/自动安装
  ;; gopls=LSP, goimports=格式化+import整理, golangci-lint=静态检查(v2),
  ;; dlv=调试, gofumpt=更严格格式化, gomodifytags/impl/gotests=代码生成
  (defvar clw/go-tools
    '((gopls         . "golang.org/x/tools/gopls@latest")
      (goimports     . "golang.org/x/tools/cmd/goimports@latest")
      (golangci-lint . "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest")
      (dlv           . "github.com/go-delve/delve/cmd/dlv@latest")
      (gofumpt       . "mvdan.cc/gofumpt@latest")
      (gomodifytags  . "github.com/fatih/gomodifytags@latest")
      (impl          . "github.com/josharian/impl@latest")
      (gotests       . "github.com/cweill/gotests/gotests@latest"))
    "常用 Go 工具及其 `go install' 路径。")
  (defun clw/go-install-tools ()
    "异步安装缺失的常用 Go 工具到 $GOPATH/bin。
手动调用：M-x clw/go-install-tools。也可被 `clw/go-ensure-tools' 自动触发。"
    (interactive)
    (unless (executable-find "go")
      (user-error "未找到 go，请先安装 Go 工具链"))
    (let ((missing (cl-remove-if
                    (lambda (cell) (executable-find (symbol-name (car cell))))
                    clw/go-tools)))
      (if (not missing)
          (message "所有 Go 工具已就绪")
        (let ((cmd (mapconcat
                    (lambda (cell) (format "go install %s" (cdr cell)))
                    missing "; ")))
          (message "异步安装 Go 工具: %s"
                   (mapconcat (lambda (c) (symbol-name (car c))) missing ", "))
          (let ((buf (get-buffer-create "*go-install*")))
            (with-current-buffer buf
              (read-only-mode -1)
              (erase-buffer)
              (insert (format "$ %s\n" cmd)))
            (display-buffer buf)
            (make-process
             :name "go-install"
             :buffer buf
             :command (list "bash" "-c" cmd)
             :sentinel (lambda (proc event)
                         (when (string-match-p "finished" event)
                           (message "Go 工具安装完成")
                           (with-current-buffer (process-buffer proc)
                             (goto-char (point-max))
                             (insert "\n[done]\n"))))))))))
  ;;@@ 进入 go-ts-mode 时：先把 GOPATH/bin 纳入 exec-path（无条件，幂等），
  ;; 再检测/异步安装缺失工具。depth 设负值确保在 eglot-ensure 之前执行，
  ;; 让 exec-path 先就绪，eglot 才能找到 gopls。
  (defun clw/go-ensure-tools ()
    "确保 GOPATH/bin 在 exec-path 与 process-environment，并检测/安装缺失工具。"
    (when (executable-find "go")
      (when-let* ((gopath (or (getenv "GOPATH")
                              (expand-file-name "go" (getenv "HOME"))))
                  (gobin (expand-file-name "bin" gopath)))
        ;; 无条件加入（幂等；目录尚不存在也无害，首次安装工具后会创建它）
        (add-to-list 'exec-path gobin)
        (add-to-list 'process-environment
                     (concat "PATH=" gobin path-separator (getenv "PATH"))))
      (let ((missing (cl-remove-if
                      (lambda (cell) (executable-find (symbol-name (car cell))))
                      clw/go-tools)))
        (when missing
          (message "检测到缺失 Go 工具(%s)，正在异步安装..."
                   (mapconcat (lambda (c) (symbol-name (car c))) missing ", "))
          (clw/go-install-tools)))))
  (add-hook 'go-ts-mode-hook #'clw/go-ensure-tools -90))

;;@@DABBREV 根据 buffer 内容进行补全
;; tbd

;;@@ISPELL, 30 里面的某些设置
(setopt text-mode-ispell-word-completion nil)
;;@@PAREN 配置 Emacs 内置的括号显示功能
;; 让光标在紧贴括号内部时也显示高亮
(setopt show-paren-when-point-inside-paren t)
;; 让光标在一行时，高亮显示该行的最外层括号
(setopt show-paren-when-point-in-periphery t)
;; 使用 overlay 显示当前屏幕内不可见的括号上下文
;; 可以使用 t(echo-area), 'overlay, 'child-frame
(setopt show-paren-context-when-offscreen 'overlay)
;;@@WHICH-KEY 显示某个按键绑定的 keymap 中的命令
(use-package which-key
  :diminish which-key-mode
  :init
  ;; 通过 C-h 或 ? 才显示 which-key buffer
  ;; 如果某些命令使用了 C-h 或 ? 可能会冲突
  (setopt which-key-show-early-on-C-h t)
  ;; 仅通过 C-h 触发
  (setopt which-key-idle-delay 10000.0)
  ;; 在随后的按键中迅速响应
  (setopt which-key-idle-secondary-delay 0.05)
  :config
  ;; 启动全局 which-key-mode
  (which-key-mode))
;;@@DIRED 显示目录
;; 按照数字顺序排列文件，即 1,2,...,10,11...
;; https://emacs.stackexchange.com/a/5650
(setopt dired-listing-switches
        "-laGh1v --group-directories-first")
;;@@ minibuffer配置
(use-package minibuffer
  :custom
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-ignore-case t)
  (enable-recursive-minibuffers t)
  (inhibit-message-regexps '("^Saving file" "^Wrote" "^Indentation setup for shell"))
  (set-message-functions '(inhibit-message))
  :init (minibuffer-depth-indicate-mode))
;;@@ simple
(use-package simple
  :bind
  ("C-x x p" . pop-to-mark-command)
  ("C-x C-." . pop-global-mark)
  ([remap capitalize-word] . capitalize-dwim)
  ("<f8>" . scratch-buffer)
  :custom
  (save-interprogram-paste-before-kill t)
  (set-mark-command-repeat-pop t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  :config
  (column-number-mode t))
;;@@ help
(use-package help
  :defer t
  :custom (help-window-select t)
  :config (temp-buffer-resize-mode))
;;@@ info
(use-package info
  :hook ((Info-mode . mixed-pitch-mode)
         (Info-mode . olivetti-mode))
  :custom-face (Info-quoted ((t (:inherit fixed-pitch)))))
;;@@ elisp
(use-package elisp-mode
  :config
  ;; Syntax highlighting of known Elisp symbols
  (if (boundp 'elisp-fontify-semantically)
      (setq elisp-fontify-semantically t)
    (use-package highlight-defined
      :hook (emacs-lisp-mode inferior-emacs-lisp-mode)))

  (with-no-warnings
    ;; Align indent keywords
    ;; @see https://emacs.stackexchange.com/questions/10230/how-to-indent-keywords-aligned
    (defun clw/lisp-indent-function (indent-point state)
      "This function is the normal value of the variable `lisp-indent-function'.
The function `calculate-lisp-indent' calls this to determine
if the arguments of a Lisp function call should be indented specially.

INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.

If the current line is in a call to a Lisp function that has a non-nil
property `lisp-indent-function' (or the deprecated `lisp-indent-hook'),
it specifies how to indent.  The property value can be:

* `defun', meaning indent `defun'-style
  \(this is also the case if there is no property and the function
  has a name that begins with \"def\", and three or more arguments);

* an integer N, meaning indent the first N arguments specially
  (like ordinary function arguments), and then indent any further
  arguments like a body;

* a function to call that returns the indentation (or nil).
  `lisp-indent-function' calls this function with the same two arguments
  that it itself received.

This function returns either the indentation to use, or nil if the
Lisp function does not specify a special indentation."
      (let ((normal-indent (current-column))
            (orig-point (point)))
        (goto-char (1+ (elt state 1)))
        (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
        (cond
         ;; car of form doesn't seem to be a symbol, or is a keyword
         ((and (elt state 2)
               (or (not (looking-at "\\sw\\|\\s_"))
                   (looking-at ":")))
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp))
              (progn (goto-char calculate-lisp-indent-last-sexp)
                     (beginning-of-line)
                     (parse-partial-sexp (point)
                                         calculate-lisp-indent-last-sexp 0 t)))
          ;; Indent under the list or under the first sexp on the same
          ;; line as calculate-lisp-indent-last-sexp.  Note that first
          ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars)
          (current-column))
         ((and (save-excursion
                 (goto-char indent-point)
                 (skip-syntax-forward " ")
                 (not (looking-at ":")))
               (save-excursion
                 (goto-char orig-point)
                 (looking-at ":")))
          (save-excursion
            (goto-char (+ 2 (elt state 1)))
            (current-column)))
         (t
          (let ((function (buffer-substring (point)
                                            (progn (forward-sexp 1) (point))))
                method)
            (setq method (or (function-get (intern-soft function)
                                           'lisp-indent-function)
                             (get (intern-soft function) 'lisp-indent-hook)))
            (cond ((or (eq method 'defun)
                       (and (null method)
                            (length> function 3)
                            (string-match "\\`def" function)))
                   (lisp-indent-defform state indent-point))
                  ((integerp method)
                   (lisp-indent-specform method state
                                         indent-point normal-indent))
                  (method
                   (funcall method indent-point state))))))))

    (setq lisp-indent-function #'clw/lisp-indent-function)))

;;@@ display-fill-column-indicator
(use-package display-fill-column-indicator
  :custom (display-fill-column-indicator-character ?\s)
  :hook (prog-mode . display-fill-column-indicator-mode)
  :hook ((emacs-startup text-scale-mode) . adjust-fill-column-indicator-stipple)
  :config
  (defun adjust-fill-column-indicator-stipple ()
    "Adjust the fill-column-indicator face with stipple."
    (let* ((w (window-font-width))
           (stipple `(,w 1 ,(apply #'unibyte-string
                                   (append (make-list (1- (/ (+ w 7) 8)) ?\0)
                                           '(1))))))
      (set-face-attribute 'fill-column-indicator nil :stipple stipple))))




;;@3 外部安装的 elisp 包
;;@@ 指定需要安装的包
(setopt package-selected-packages
        '(;; 安装的包列表
          markdown-mode ; 提供 emacs 中的 markdown 支持
          cnfonts ; 中英文字体对其，通过 `cnfonts-edit-profile' 进行设定
          winum ; 快速的窗口间跳转
          avy ; 快速跳转（M-j 输入字符序列跳转）
          pyim ; 拼音输入法
          pyim-basedict ; pyim 依赖项
          popup ; pyim 依赖项
          vertico ; M-x 补全
          marginalia
          eldoc-box ; 提供悬浮的 eldoc 补全
          vundo ; 可视化 undo，undo-tree 的替代品
          magit ; 强大的 git UI
          ibuffer-vc ; 为 ibuffer 添加基于项目的分组
          orderless ; 乱序补全后端
          consult ; 异步查询框架
          consult-eglot
          wgrep ; 基于 grep 的批量替换工具
          devdocs ; 提供来自 devdocs 的文档支持
          buffer-env ; 提供基于 direnv 的 buffer-local 环境
          expand-region ; 选中扩展
          diminish ; 让某些 mode 标识不在 modeline 显示
          ;;yasnippet ; 强大的代码模板工具
          breadcrumb ; 面包屑导航
          embark ; DWIM 工具
          embark-consult
          popper ; 类似 popwin 但更好用
          expreg ; 类似 expand-region，但更好
          corfu ; corfu 补全前端，company 的替代品
          tempel ; 代码模板引擎
          cape ; 为 corfu 提供一些后端
          envrc ; 类似 buffer-env
          powershell ; 在 Emacs 中打开 powershell, windows 
          emacsql ; 统一的 SQL 前端
          f ; 稍微好用一点的文件 API
          p-search ; 某种搜索工具
          doom-themes
          doom-modeline
          rainbow-delimiters
          highlight-escape-sequences
          multiple-cursors
          move-dup          
          symbol-overlay
          ws-butler
          diff-hl
          mixed-pitch
          verb
          paredit
          puni
          aggressive-indent
          apheleia
          jinx
          highlight-quoted
          treesit-auto
          ))
(defun clw/install-packages ()
  "Install/refresh all selected packages (ELPA + VC).
Run after changing `package-selected-packages' or `package-vc-selected-packages'."
  (interactive)
  (package-install-selected-packages)
  (package-vc-install-selected-packages))

(defun clw/package-missing-p ()
  "Return non-nil if any selected package is missing."
  (or (cl-some (lambda (pkg) (not (package-installed-p pkg)))
               package-selected-packages)
      (cl-some (lambda (spec)
                 (not (file-directory-p
                       (expand-file-name (symbol-name (car spec))
                                         package-user-dir))))
               package-vc-selected-packages)))
;;@@ 安装来自 git 仓库的包
(setopt package-vc-selected-packages
        '(
          ;; (yyorg-bookmark :url "https://github.com/include-yy/yyorg-bookmark")
          ;; (chodf :url "https://github.com/include-yy/chodf")
          ;; (rescript-mode :url "https://github.com/include-yy/rescript-mode")
          ;;(ox-w3ctr :url "https://github.com/include-yy/ox-w3ctr")
          ;;(tetosave :url "https://github.com/yyelpa/tetosave") ; 自动保存
          ;;(consult-everything :url "https://github.com/jthaman/consult-everything")
          ;;(wgsl-ts-mode :url "https://github.com/acowley/wgsl-ts-mode")
          (yynt :url "https://github.com/include-yy/yynt")
          (persistent-cached-load-filter
           :url "https://github.com/include-yy/persistent-cached-load-filter")
          ))

(when (clw/package-missing-p)
  (clw/install-packages))
;;@@ theme
(use-package doom-themes
  :functions clw/load-theme
  :init (clw/load-theme 'doom-oksolar-light)
  :config
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config)
  )
;;@@ doom-modeline
(use-package doom-modeline
  :defer t
  :hook after-init
  )
                                        ;@@MARKDOWN-MODE
(use-package markdown-mode
  :mode "\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\|mdx\\)\\'")
;;@@ CNFONTS
(use-package cnfonts
  :defer t
  :hook after-init
  :init
  (setopt cnfonts-personal-fontnames
          '(;; English
	    ("Maple Mono NF CN" "Noto Sans Mono" "Noto Sans" "Noto Sans Mono CJK SC" "Roboto Mono")
	    ;; Chinese
	    ("Maple Mono NF CN")
	    ;; EXT-B
	    ()
	    ;; Symbol
	    ()
	    ;; Decorate
	    ())))
;;@@FIND-FILE-IN-PROJECT 方便的项目内文件搜索
;;te 设置 ffip 在 Windows 下的相关选项
;; 在 Windows 上需要设定 `ffip-find-executable' 为 find
;; 也可考虑使用 rust 编写的 fd，设置 `ffip-use-rust-fd' 为 `t'
;; 并设定 `ffip-find-executable' 为 fd 路径
;; 注意：使用 fd 必须设定 `ffip-use-rust-fd'，fd 与 find 命令行参数不一致
;; 使用 `project-find-file' 也行
(use-package find-file-in-project
  :disabled
  :bind ("C-c f" . find-file-in-project)
  :config
  (clw/add-to-group 'ffip-find-executable)
  (clw/add-to-group 'ffip-use-rust-fd))
;;@@WINUM 窗口间跳转
(use-package winum
  :defer t
  :hook (after-init . winum-mode)
  :config
  (set-face-attribute 'winum-face nil
                      :foreground "DeepPink"
                      :underline "DeepPink"
                      :weight 'bold)
  (winum-set-keymap-prefix (kbd "C-c")))
;;@@PYIM elisp 实现的中文输入法
(use-package pyim
  :init (setopt default-input-method "pyim")
  :defer t
  :config
  (use-package pyim-basedict)
  (use-package popup)
  (pyim-basedict-enable)
  (pyim-default-scheme 'xiaohe-shuangpin))
;;@@ VERTICO 更好的 icomplete 和 ido
(use-package vertico
  :config
  (vertico-mode 1)
  (setopt vertico-resize 'nil))
;;@@ vertico-sort
(use-package vertico-sort
  :after vertico)
;;@@ marginalia
(use-package marginalia
  :init (marginalia-mode))
;;@@CORFU 试试更加轻量和现代的 corfu
(use-package corfu
  :defer t
  :init
  ;; 允许 cycle
  (setopt corfu-cycle t)
  ;; 允许自动触发 corfu 补全
  (setopt corfu-auto t)
  ;; 在补全时若候选项小于 3 则不弹出选项
  (setopt completion-cycle-threshold 3)
  ;; 在输入字符 0.3 秒后触发 corfu
  (setopt corfu-auto-delay 0.3)
  ;; 无候选项不显示 no match
  (setopt corfu-quit-no-match t)
  (add-hook 'prog-mode-hook
            (lambda () (corfu-mode)))
  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input)
                (eq (current-local-map) read-passwd-map))
      ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
      (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
                  corfu-popupinfo-delay nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode))))
;;@@ cape
(use-package cape
  :after corfu
  :bind (("C-c p p" . completion-at-point)
         ("C-c p t" . complete-tag)
         ("C-c p d" . cape-dabbrev)
         ("C-c p f" . cape-file)
         ("C-c p s" . cape-elisp-symbol)
         ("C-c p e" . cape-elisp-block)
         ("C-c p a" . cape-abbrev)
         ("C-c p l" . cape-line)
         ("C-c p w" . cape-dict))
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster))
;;@@ELDOC-BOX 悬浮式 ELDOC
(use-package eldoc-box
  :if (display-graphic-p)
  :hook (eglot-managed-mode . eldoc-box-hover-mode)
  :bind ("C-;" . eldoc-box-help-at-point)
  :custom-face
  (eldoc-box-body ((t (:inherit (variable-pitch)))))
  (eldoc-box-markdown-separator ((t (:inherit (fringe))))))
;;@@VUNDO 可视化 undo，比 undo-tree 更好
(use-package vundo
  :bind ("C-?" . vundo))
;;@@AVY 快速跳转（输入字符序列，显示标签按标签跳转）
(use-package avy
  :commands (avy-goto-word-1 avy-goto-char-2 avy-goto-char-timer)
  :config
  (setq avy-timeout-seconds 0.6)
  (setq avy-keys '( ?f ?d ?s ?a ?g ?q ?e ?r
                    ?c ?v ?p ?. ?, ;; ?2 ?3 ?9 ?8
                    ?u ?/ ?b ?n ?i ?o ?' ?l ?j))
  (setq avy-single-candidate-jump nil)
  (setq avy-dispatch-alist '((?m . avy-action-mark)
                             (?$ . avy-action-ispell)
                             (?z . avy-action-zap-to-char)
                             (?  . avy-action-embark)
                             (?= . avy-action-define)
                             (23 . avy-action-zap-to-char)
                             (67108896 . avy-action-mark-to-char)
                             (?h . avy-action-helpful)
                             (?x . avy-action-exchange)

                             (11 . avy-action-kill-line)
                             (25 . avy-action-yank-line)

                             (?w . avy-action-copy)
                             (?k . avy-action-kill-stay)
                             (?y . avy-action-yank)
                             (?t . avy-action-teleport)

                             (?W . avy-action-copy-whole-line)
                             (?K . avy-action-kill-whole-line)
                             (?Y . avy-action-yank-whole-line)
                             (?T . avy-action-teleport-whole-line)
                             ))

  ;; (define-advice avy-goto-char-timer (:around (orig-fn &optional arg)
  ;;                                     single-candidate-jump)
  ;;   (let ((avy-single-candidate-jump t))
  ;;     (funcall orig-fn arg)))

  (defun avy-action-exchange (pt)
    "Exchange sexp at PT with the one at point."
    (set-mark pt)
    (transpose-sexps 0))

  (defun avy-action-helpful (pt)
    (save-excursion
      (goto-char pt)
      (call-interactively #'display-local-help))
    (select-window
     (cdr (ring-ref avy-ring 0)))
    t)

  (defun avy-action-define (pt)
    (cl-letf (((symbol-function 'keyboard-quit)
               #'abort-recursive-edit))
      (save-excursion
        (goto-char pt)
        (dictionary-search-dwim))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)

  (defun avy-action-embark (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (embark-act))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)

  (defun avy-action-kill-line (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (kill-line))
      (avy-resume))
    (select-window
     (cdr (ring-ref avy-ring 0)))
    t)

  (defun avy-action-copy-whole-line (pt)
    (save-excursion
      (goto-char pt)
      (cl-destructuring-bind (start . end)
          (bounds-of-thing-at-point 'line)
        (copy-region-as-kill start end)))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun avy-action-kill-whole-line (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (kill-whole-line)
          (avy-resume)))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun avy-action-yank-whole-line (pt)
    (avy-action-copy-whole-line pt)
    (save-excursion (yank))
    t)

  (defun avy-action-teleport-whole-line (pt)
    (avy-action-kill-whole-line pt)
    (save-excursion (yank)) t)

  (defun avy-action-mark-to-char (pt)
    (activate-mark)
    (goto-char pt))

  (defun clw/avy-goto-char-this-window (&optional arg)
    "Goto char in this window with hints."
    (interactive "P")
    (let ((avy-all-windows t)
          (current-prefix-arg (if arg 4)))
      (call-interactively 'avy-goto-word-1)))

  (defun clw/avy-isearch (&optional arg)
    "Goto isearch candidate in this window with hints."
    (interactive "P")
    (let ((avy-all-windows)
          (current-prefix-arg (if arg 4)))
      (call-interactively 'avy-isearch)))

  (defun clw/avy--read-char-2 ()
    "Read two characters from the minibuffer, return a 2-char string.
RET is converted to newline; C-g quits; backspace on the second char
re-reads from the first char."
    (let (c1 c2)
      (while (null c1)
        (let ((c (read-char "char 1: " t)))
          (cond
           ((memq c '(?\s ?\b 7)) (keyboard-quit))
           (t (setq c1 c)))))
      (while (null c2)
        (let ((c (read-char "char 2: " t)))
          (cond
           ((memq c '(?\r 7)) (keyboard-quit))
           ((memq c '(8 127)) (setq c1 nil c2 nil))
           (t (setq c2 c)))))
      (when (eq c1 ?\r) (setq c1 ?\n))
      (when (eq c2 ?\r) (setq c2 ?\n))
      (string c1 c2)))

  (defun clw/avy-next-char-2 (&optional str2 arg)
    "Go to the next occurrence of two characters"
    (interactive (list
                  (clw/avy--read-char-2)
                  current-prefix-arg))
    (let* ((ev last-command-event)
           (echo-keystrokes nil))
      (push-mark (point) t)
      (if (search-forward str2 nil t
                          (+ (if (looking-at (regexp-quote str2))
                                 1 0)
                             (or arg 1)))
          (backward-char 2)
        (pop-mark)))

    (set-transient-map
     (let ((map (make-sparse-keymap)))
       (define-key map (kbd ";") (lambda (&optional arg) (interactive)
                                   (clw/avy-next-char-2 str2 arg)))
       (define-key map (kbd ",") (lambda (&optional arg) (interactive)
                                   (clw/avy-previous-char-2 str2 arg)))
       map)))

  (defun clw/avy-previous-char-2 (&optional str2 arg)
    "Go to the next occurrence of two characters"
    (interactive (list
                  (clw/avy--read-char-2)
                  current-prefix-arg))
    (let* ((ev last-command-event)
           (echo-keystrokes nil))
      (push-mark (point) t)
      (unless (search-backward str2 nil t (or arg 1))
        (pop-mark)))

    (set-transient-map
     (let ((map (make-sparse-keymap)))
       (define-key map (kbd ";") (lambda (&optional arg) (interactive)
                                   (clw/avy-next-char-2 str2 arg)))
       (define-key map (kbd ",") (lambda (&optional arg) (interactive)
                                   (clw/avy-previous-char-2 str2 arg)))
       map)))

  (defun clw/avy-copy-line-no-prompt (arg)
    (interactive "p")
    (avy-copy-line arg)
    (beginning-of-line)
    (zap-to-char 1 32)
    (delete-forward-char 1)
    (move-end-of-line 1))

  (defun clw/avy-link-hint (&optional win)
    "Find all visible buttons and links in window WIN and open one with Avy.

The current window is chosen if WIN is not specified."
    (interactive)
    (with-selected-window (or win
                              (setq win (selected-window)))
      (let* ((avy-single-candidate-jump t) match all-buttons)

        ;; SHR links
        (save-excursion
          (goto-char (window-start))
          (while (and
                  (<= (point) (window-end))
                  (setq match
                        (text-property-search-forward 'category 'shr t nil)))
            (let ((st (prop-match-beginning match)))
              (push
               `((,st . ,(1+ st)) . ,win)
               all-buttons))))

        ;; Collapsed sections
        (thread-last (overlays-in (window-start) (window-end))
                     (mapc (lambda (ov)
                             (when (or (overlay-get ov 'button)
                                       (eq (overlay-get ov 'face)
                                           'link))
                               (let ((st (overlay-start ov)))
                                 (push
                                  `((,st . ,(1+ st)) . ,win)
                                  all-buttons))))))

        (when-let
            ((_ all-buttons)
             (avy-action
              (lambda (pt)
                (goto-char pt)
                (let (b link)
                  (cond
                   ((and (setq b (button-at (1+ pt)))
                         (button-type b))
                    (button-activate b))
                   ((shr-url-at-point pt)
                    (shr-browse-url))
                   ((setq link (or (get-text-property pt 'shr-url)
                                   (thing-at-point 'url)))
                    (browse-url link)))))))
          (let ((cursor-type nil))
            (avy-process all-buttons))))))

  (custom-set-faces
   '(avy-lead-face
     ((((background dark))
       :foreground "LightCoral" :background "Black"
       :weight bold :underline t)
      (((background light))
       :foreground "DarkRed" :background unspecified :box (:line-width (1 . -1)) :height 0.95
       :weight bold)))
   '(avy-lead-face-0 ((t :background unspecified :inherit avy-lead-face)))
   '(avy-lead-face-1 ((t :background unspecified :inherit avy-lead-face)))
   '(avy-lead-face-2 ((t :background unspecified :inherit avy-lead-face))))

  (define-advice avy-goto-line-below (:around (orig-fn &rest args) no-default-action)
    "Ensure no default `avy-action' when moving, and go to end of line."
    (let ((avy-action)) (apply orig-fn args))) ;; (end-of-line)

  (define-advice avy-goto-line-above (:around (orig-fn &rest args) no-default-action)
    "Ensure no default `avy-action' when moving, and go to end of line."
    (let ((avy-action)) (apply orig-fn args))) ;; (end-of-line)

  ;; Jump to all paren types with [ and ]
  (advice-add 'avy-jump :filter-args
              (defun clw/avy-jump-parens (args)
                (let ((new-regex
                       (clw/avy-replace-syntax-class (car args))))
                  (cons new-regex (cdr args)))))

  (defun clw/avy-replace-syntax-class (regex)
    (thread-last regex
                 (string-replace "\\[" "\\s(")
                 (string-replace "\\]" "\\s)")
                 (string-replace ";" "\\(?:;\\|:\\)")
                 (string-replace "'" "\\(?:'\\|\"\\)")))

  (defun clw/avy-goto-char-timer (&optional arg)
    "Read one or many consecutive chars and jump to the first one.
The window scope is determined by `avy-all-windows' (ARG negates it).

This differs from Avy's goto-char-timer in how it processes parens."
    (interactive "P")
    (let ((avy-all-windows (if arg
                               (not avy-all-windows)
                             avy-all-windows))
          (avy-single-candidate-jump nil))
      (avy-with avy-goto-char-timer
        (setq avy--old-cands (avy--read-candidates
                              (lambda (str) (clw/avy-replace-syntax-class
                                             (regexp-quote str)))))
        (avy-process avy--old-cands))))

  :bind (("C-M-'"   . avy-resume)
         ("C-'"     . clw/avy-goto-char-this-window)
         ("M-j"     . clw/avy-goto-char-timer)
         ("M-s y"   . avy-copy-line)
         ("M-s M-y" . avy-copy-region)
         ("M-s M-k" . avy-kill-whole-line)
         ("M-s j"   . avy-goto-char-2)
         ("M-s M-p" . avy-goto-line-above)
         ("M-s M-n" . avy-goto-line-below)
         ("M-s M-l" . avy-goto-end-of-line)
         ("M-s C-w" . avy-kill-region)
         ("M-s M-w" . avy-kill-ring-save-region)
         ("M-s t"   . avy-move-line)
         ("M-s M-t" . avy-move-region)
         ;; ("M-s s"   . clw/avy-next-char-2)
         ;; ("M-s r"   . clw/avy-previous-char-2)
         ("M-s z"   . clw/avy-copy-line-no-prompt)
         :map isearch-mode-map
         ("C-'"     . clw/avy-isearch)
         ("M-j"     . clw/avy-isearch)))
;;@@ORDERLESS 好用的模糊搜索插件
(use-package orderless
  :config
  (setopt completion-styles '(orderless basic))
  (setopt completion-category-overrides
          '((file (styles basic partial-completion))
            ;; eglot 补全默认强制走 eglot--dumb-flex，覆盖为 orderless
            ;; 让 corfu 前端的 LSP 候选也支持多词任意顺序匹配
            (eglot-capf (styles orderless basic))))
  )
;;@@ consult
(use-package consult
  :defer 0.5
  :bind (([remap repeat-complex-command] . consult-complex-command)
         ([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap bookmark-jump] . consult-bookmark)
         ([remap goto-line] . consult-goto-line)
         ([remap imenu] . consult-imenu)
         ([remap yank-pop] . consult-yank-pop)
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ("C-s" . consult-line)
         ([remap Info-search] . consult-info)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-s d" . consult-fd)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         :map minibuffer-local-map
         ("M-s" . consult-history))
  :custom
  (register-preview-delay 0.5)
  (register-preview-function #'consult-register-format)
  (consult-narrow-key "<")
  :commands consult--customize-put
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   :preview-key "M-.")
  )
;;@@ consult-eglot
(use-package consult-eglot
  :after (consult eglot)
  :bind (:map eglot-mode-map ("M-g s" . consult-eglot-symbols)))
;;@@ embark
(use-package embark
  :bind
  ("C-." . embark-act)
  ("M-." . embark-dwim)
  ("C-h b" . embark-bindings)
  ("C-h B" . embark-bindings-at-point)
  ("M-n" . embark-next-symbol)
  ("M-p" . embark-previous-symbol)
  :custom
  (embark-quit-after-action nil)
  (prefix-help-command #'embark-prefix-help-command)
  (embark-indicators '(embark-minimal-indicator
                       embark-highlight-indicator
                       embark-isearch-highlight-indicator))
  (embark-cycle-key ".")
  (embark-help-key "?")
  :config
  (setq embark-candidate-collectors
        (cl-substitute 'embark-sorted-minibuffer-candidates
                       'embark-minibuffer-candidates
                       embark-candidate-collectors))
  (delete 'embark-target-flymake-at-point embark-target-finders))
;;@@EMBARK-CONSULT 联动 embark 与 consult
(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))
;;@@EXPREG 可以使用 tree sitter 的 expand-region
(use-package expreg
  :when (treesit-available-p)
  :bind ("C-=" . expreg-expand))
;;@@BREADCRUMB 面包屑导航
(use-package breadcrumb
  :defer t
  :hook (after-init . breadcrumb-mode))

;;@@POPPER 管理弹出的各种临时 buffer
;; 这样就不会打破 Window 布局
(use-package popper
  :bind (("C-`" . popper-toggle)
         ("M-`" . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setopt popper-reference-buffers
          '("\\*Messages\\*" "Output\\*$"
            "\\*Async Shell Command\\*"
            "\\*Completions\\*"
            "\\*eshell.*\\*" eshell-mode
            "\\*Occur\\*"
            help-mode
            compilation-mode
            shell-mode "^\\*shell.*\\*"
            "\\*xref\\*"))
  :config
  (popper-mode 1)
  (popper-echo-mode 1))
;;@@ENVRC Linux 上管理开发环境
;; 可以执行 `envrc-allow' 和 `envrc-deny' 来开启和关闭某目录下的 .envrc
(use-package envrc
  :when sys/linuxp
  :defer t
  :hook (after-init . envrc-global-mode))
;;@@TEMPEL 好用的代码模板工具
(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :init
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))
  (add-hook 'prog-mode-hook 'tempel-setup-capf))
;;@@ rainbow-delimiters  括号高亮增强包
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))
;;@@ highlight-escape-sequences 给字符串和正则里的转义字符（如 \n、\t、\x1b）上色，让你一眼看清哪些字符是“特殊的
(use-package highlight-escape-sequences
  :hook (after-init . hes-mode))
;;@@ multiple-cursors 让你同时在多个位置（光标）进行编辑
(use-package multiple-cursors
  :bind
  ("C-S-c C-S-c" . 'mc/edit-lines)
  ("C->" . 'mc/mark-next-like-this)
  ("C-<" . 'mc/mark-previous-like-this)
  ("C-c C-<" . 'mc/mark-all-like-this)
  ("C-\"" . 'mc/skip-to-next-like-this)
  (:map mc/keymap ("M-N" . 'mc/insert-numbers))
  :config
  (add-to-list 'mc/unsupported-minor-modes 'auto-save-visited-mode))
;;@@ move-dup 一键复制当前行 / 区域，或将行/区域向上/向下移动。
(use-package move-dup
  :bind
  ("C-c d" . move-dup-duplicate-down)
  ("C-c u" . move-dup-duplicate-up)
  ([M-up] . move-dup-move-lines-up)
  ([M-down] . move-dup-move-lines-down))
;;@@ treesit-auto
(use-package treesit-auto
  :defer t
  :hook ((prog-mode conf-mode) . treesit-auto-mode))
;;@@ symbol-overlay 一键高亮当前光标下的符号（变量名 / 函数名 / 关键字），并在所有出现位置之间快速跳转。
(use-package symbol-overlay
  :hook ((prog-mode html-mode conf-mode) . symbol-overlay-mode)
  :bind (:map symbol-overlay-mode-map
         ("M-i" . symbol-overlay-put)
         ("M-I" . symbol-overlay-remove-all)
         ("M-n" . symbol-overlay-jump-next)
         ("M-p" . symbol-overlay-jump-prev)))

;;@@ jinx 新一代实时拼写检查器
(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind ("M-$" . jinx-correct)
  :custom (jinx-languages "en_US")
  :config (add-to-list 'jinx-exclude-regexps '(t "\\cc")))
;;@@ ws-butler
(use-package ws-butler
  :hook (emacs-startup . ws-butler-global-mode))
;;@@ diff-hl
(use-package diff-hl
  :if (display-graphic-p)
  :bind (:map diff-hl-mode-map
         ("<left-fringe> <mouse-1>" . diff-hl-diff-goto-hunk)
         ("M-]" . diff-hl-next-hunk)
         ("M-[" . diff-hl-previous-hunk))
  :hook ((after-init . global-diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :commands diff-hl-magit-post-refresh
  :config
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))
;;@@ magit
(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-diff-refine-hunk t)
  (magit-module-sections-nested nil)
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)
  (magit-bury-buffer-function 'magit-restore-window-configuration)
  :init
  (defmacro aquamacs/fullframe-mode (mode)
    "Configure buffers that open in MODE to start out full-frame."
    `(add-to-list 'display-buffer-alist
                  (cons (cons 'major-mode ,mode)
                        (list 'display-buffer-full-frame))))
  (aquamacs/fullframe-mode 'magit-status-mode)
  :commands magit-add-section-hook
  :config
  (put 'magit-clean 'disabled nil)
  (magit-add-section-hook 'magit-status-sections-hook
                          'magit-insert-modules
                          'magit-insert-unpulled-from-upstream)
  (with-eval-after-load "magit-submodule"
    (dolist (module-section '(magit-insert-modules-unpulled-from-pushremote
                              magit-insert-modules-unpushed-to-upstream
                              magit-insert-modules-unpushed-to-pushremote))
      (remove-hook 'magit-module-sections-hook module-section))))
;;@@ mixed pitch 字体混合显示插件
(use-package mixed-pitch
  :defer t
  :init
  ;; Fix the `nerd-icons-corfu' display issue
  (with-eval-after-load 'corfu
    (define-advice corfu--make-buffer (:around (oldfun &rest args))
      (let ((face-remapping-alist nil))
        (apply oldfun args)))))
;;@@ verb
(use-package verb
  :after org
  :bind (:map verb-response-body-mode-map
         ("q" . kill-buffer-and-window))
  :bind-keymap ("C-c C-r" . verb-command-map)
  :init (unbind-key "C-c C-r" org-mode-map))
;;@@ paredit
(use-package paredit
  :hook (emacs-lisp-mode . enable-paredit-mode)
  :config
  (setq paredit-lighter " Par")
  (dolist (binding '("C-<left>" "C-<right>" "M-s" "M-?"))
    (define-key paredit-mode-map (read-kbd-macro binding) nil)))
;;@@ puni
(use-package puni
  :hook ((prog-mode . puni-mode)
         (emacs-lisp-mode . (lambda () (puni-mode -1))))
  :bind (:map puni-mode-map
         ("M-(" . puni-wrap-round)
         ("C-(" . puni-slurp-backward)
         ("C-)" . puni-slurp-forward)
         ("C-}" . puni-barf-forward)
         ("C-{" . puni-barf-backward)
         ("M-<up>" . puni-splice-killing-backward)
         ("C-w" . nil)))
;;@@ aggressive-indent
(use-package aggressive-indent
  :hook (emacs-lisp-mode . aggressive-indent-mode))
;;@@ APHELEIA 保存时自动格式化，不移动光标
(use-package apheleia
  :hook (prog-mode . apheleia-mode)
  :config
  ;; Python 优先使用 ruff（更快），不可用时回退到 black
  (setf (alist-get 'python-mode apheleia-mode-alist)
        (if (executable-find "ruff") '(ruff-isort ruff) 'black))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        (if (executable-find "ruff") '(ruff-isort ruff) 'black))
  ;; Rust 使用 rustfmt 格式化
  (setf (alist-get 'rust-ts-mode apheleia-mode-alist) 'rustfmt)
  (setf (alist-get 'rust-mode apheleia-mode-alist) 'rustfmt)
  ;; Go 优先 goimports（兼顾格式化与 import 整理），未装则回退 gofmt
  (setf (alist-get 'go-ts-mode apheleia-mode-alist)
        (if (executable-find "goimports") 'goimports 'gofmt))
  (setf (alist-get 'go-mode apheleia-mode-alist)
        (if (executable-find "goimports") 'goimports 'gofmt)))
;;@@ highlight-quoted
(use-package highlight-quoted
  :hook (emacs-lisp-mode . highlight-quoted-mode))
;;@@P-SEARCH 检索工具
(use-package p-search
  :defer t
  :config
  (defun clw/p-search-query--command (fun term cmd)
    (let* ((term-str (p-search--rx-to-string term cmd))
           (case-insensitive-p
            (get-text-property 0 'p-search-case-insensitive term-str)))
      (if (eq cmd :grep)
          `(,grep-program "-r" "-c" ,@(and case-insensitive-p '("--ignore-case"))
                          ,term-str ".")
        (funcall fun term cmd))))
  (advice-add 'p-search-query--command
              :around #'clw/p-search-query--command))
;;@4 一些零散的小函数和设定
;;@@ 打开 init 文件
(defun clw/open-init ()
  "Open my init file"
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;;@@ 增强 C-x <num> 系列的 Window 管理功能
(defun clw/split-and-move-to-other-window (fun)
  (lambda (&optional arg)
    (interactive "P")
    (funcall fun)
    (let ((target-window (next-window)))
      (set-window-buffer target-window (other-buffer))
      (unless arg
        (select-window target-window)))))
(defalias 'clw/split-window-below (clw/split-and-move-to-other-window
                                   'split-window-below))
(defalias 'clw/split-window-right (clw/split-and-move-to-other-window
                                   'split-window-right))

(defun clw/delete-other-windows ()
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(defun clw/split-change-place (fun)
  "Kill any other windows and re-split current window in one way.
the current window is on the left/top half of the frame.
way-func can be | or _"
  (lambda ()
    (interactive)
    (let ((other-buf (and (next-window) (window-buffer (next-window)))))
      (delete-other-windows)
      (funcall fun)
      (when other-buf
        (set-window-buffer (next-window) other-buf)))))
(defalias 'clw/split-change-right (clw/split-change-place 'split-window-right))
(defalias 'clw/split-change-below (clw/split-change-place 'split-window-below))

(bind-key "C-x 1" 'clw/delete-other-windows)
(bind-key "C-x 2" 'clw/split-window-below)
(bind-key "C-x 3" 'clw/split-window-right)
(bind-key "C-x |" 'clw/split-change-right)
(bind-key "C-x _" 'clw/split-change-below)

;;@@ 显示修改过的按键绑定
(defun clw/show-keys ()
  "显示所有通过 `use-package' 或 `bind-key' 修改的按键绑定"
  (interactive)
  (describe-personal-keybindings))

;;@@ 文字计数，可以处理中文和英文
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; http://www.emacswiki.org/emacs/download/basic-toolkit.el
(defun count-ce-words (beg end)
  "Count Chinese and English words in marked region."
  (interactive "r")
  (let ((cn-word 0)
        (en-word 0)
        (total-word 0)
        (total-byte 0))
    (setq cn-word (count-matches "\\cc" beg end)
          en-word (count-matches "\\w+\\W" beg end))
    (setq total-word (+ cn-word en-word)
          total-byte (+ cn-word (abs (- beg end))))
    (message (format "Total: %d (CN: %d, EN: %d) words, %d bytes."
                     total-word cn-word en-word total-byte))))

;;@@ 删除 *{name}* 的 buffer
(defun kill-unused-buffers ()
  (interactive)
  (ignore-errors
    (save-excursion
      (dolist (buf (buffer-list))
        (set-buffer buf)
        (if (and (string-prefix-p "*" (buffer-name))
                 (string-suffix-p "*" (buffer-name)))
            (kill-buffer buf))))))

;;@@ 对整个 buffer 进行缩进
(defun indent-buffer ()
  "Automatic format current buffer."
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max) nil)
    (delete-trailing-whitespace)
    (untabify (point-min) (point-max))))

;;@@CLWINIT-MODE 用于 init.el 浏览各配置节点的 minor-mode，使用了 outline-minor-mode
(defvar-keymap clwinit-mode-map
  :doc "部分来自 outline-mode 的键绑定"
  "C-c C-n" #'outline-next-visible-heading
  "C-c C-p" #'outline-previous-visible-heading
  "C-c C-u" #'outline-up-heading
  "C-c C-a" #'outline-show-all
  "C-c C-o" #'outline-hide-other
  "C-c C-j" #'consult-outline
  )

(define-minor-mode clwinit-mode
  "用于浏览配置文件各节点的 minor-mode，添加了部分 outline-mode 按键绑定"
  :keymap clwinit-mode-map)

(defun clw/init-setup ()
  (interactive)
  (when (equal (file-truename (expand-file-name "~/.emacs.d/init.el"))
               (file-truename (buffer-file-name (current-buffer))))
    (setq-local outline-regexp ";;; init.el ---\\|;;; Code\\|;;@+")
    (setq-local outline-heading-alist '((";;; init.el ---" . 1) (";;; Code" . 1)
                                        (";;@" . 2) (";;@@" . 3) (";;@@@ . 4")))
    (setq-local outline-minor-mode-use-buttons 'in-margins)
    (setq-local outline-minor-mode-highlight 'override)
    (setq-local outline-minor-mode-cycle t)
    (setq-local outline-level 'outline-level)
    (outline-minor-mode)
    (clwinit-mode)))

;; 把末尾 Local Variables 的 eval form 注册为安全，避免每次打开 init.el 弹窗确认
(add-to-list 'safe-local-eval-forms
             '(when (fboundp 'clw/init-setup) (clw/init-setup)))

;; Local Variables:
;; eval: (when (fboundp 'clw/init-setup) (clw/init-setup))
;; End:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init.el ends here

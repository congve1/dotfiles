# ==============================================================================
# Powerlevel10k 即时提示符（必须放在文件最顶部，加速终端启动）
# 所有需要交互式输入(密码/y/n确认)的代码务必写在本段上方
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# Zinit 插件管理器 自动安装逻辑
# ==============================================================================
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" --depth=1 && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ==============================================================================
# ZSH 原生基础环境配置
# ==============================================================================
bindkey -e
setopt extendedglob nomatch notify
unsetopt beep

COMPLETION_WAITING_DOTS="true"
ENABLE_CORRECTION="true"

# OMZ 公共库（去掉 completion.zsh —— compinit 统一由下方 fast-syntax-highlighting 入口执行）
zinit lucid for OMZ::lib/key-bindings.zsh
zinit wait lucid for \
    OMZ::lib/git.zsh \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/correction.zsh \
    OMZ::lib/history.zsh \
    OMZ::lib/theme-and-appearance.zsh \
    OMZ::plugins/git/git.plugin.zsh \
    OMZ::plugins/git-extras/git-extras.plugin.zsh

# 补全源：只注册，不跑 compinit（全 shell 唯一的 compinit 在 fast-syntax-highlighting 的 atinit 里）
zinit wait lucid blockf for zsh-users/zsh-completions

# fast-syntax-highlighting（唯一 compinit 入口）
zinit wait"0" lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    atload"FAST_HIGHLIGHT[chroma-git]=0" \
    zdharma-continuum/fast-syntax-highlighting

# zsh-autosuggestions 幽灵提示已停用（用 fzf Ctrl+R 搜历史替代）。
# 想恢复时取消下面三行注释即可（atload 必须紧贴插件上一行）：
# zinit wait"0" lucid for \
#     atload"bindkey '^J' autosuggest-accept" \
#     zsh-users/zsh-autosuggestions
# 只想调淡灰字而不关插件的话，改用：
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

# forgit git交互式工具 + 自动配对
zinit wait"1" lucid for \
    atinit"forgit_ignore='fgi'" \
    wfxr/forgit \
    hlissner/zsh-autopair

# ==============================================================================
# fzf：gh-r 装二进制 + raw 官方补全/键绑定 + fzf-tab
# ==============================================================================
zinit ice lucid wait"1" from"gh-r" as"program" pick"fzf" bpick"*linux_amd64.tar.gz"
zinit load junegunn/fzf

zinit ice lucid wait"1" as"completion"
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh

zinit ice lucid wait"1"
zinit snippet https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh

# fzf-tab 放在 compinit 之后（wait"2"）
zinit ice lucid wait"2"
zinit light Aloxaf/fzf-tab

# fzf 全局外观：高度/反序/边框
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
# ctrl+t 搜文件，右侧用 eza 预览（没装 fd 时自动兜底用 find）
export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git 2>/dev/null || find . -type f -not -path "*/.git/*"'
export FZF_CTRL_T_OPTS="--preview 'eza -1 --color=always {} 2>/dev/null || cat {}'"
# alt+c 搜目录并 cd
export FZF_ALT_C_OPTS="--preview 'eza -1 --color=always {}/'"

# fzf-tab 配置
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# 大小写智能匹配：输小写能匹配大写文件名
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# 补全结果分组显示（文件/目录/命令分开）
zstyle ':completion:*' group-name ''
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# ==============================================================================
# eza：exa 的社区维护 fork，gh-r 装二进制（tar.gz 顶层即 eza 可执行文件）
# ==============================================================================
zinit ice lucid wait"1" from"gh-r" as"program" pick"eza" bpick"*x86_64-unknown-linux-gnu.tar.gz"
zinit light eza-community/eza
alias ls='eza'
alias ll='eza -l --git'
alias lt='eza -T'

# ==============================================================================
# zoxide：gh-r 装二进制，加载完成后立刻 init（自带 z 跳转 / zi 交互式跳转）
# ==============================================================================
zinit ice lucid wait"0" from"gh-r" as"program" pick"zoxide" \
     bpick"*x86_64-unknown-linux-musl.tar.gz" \
     atload'eval "$(zoxide init zsh)"'
zinit light ajeetdsouza/zoxide

# alacritty 补全（必须用 raw 地址，/blob/ 返回的是 HTML）
zinit ice lucid wait"1" as"completion"
zinit snippet https://raw.githubusercontent.com/alacritty/alacritty/master/extra/completions/_alacritty

# 可能是最好的主题提示，在zsh下有极高的性能
zinit ice depth=1
zinit light romkatv/powerlevel10k

# ==============================================================================
# 历史记录（HISTFILE 必须显式设置，否则 zsh 不保存历史）
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=500000
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS      # 去掉多余空格再入库，历史更干净
setopt HIST_VERIFY             # 按 !!/!$ 展开后先显示再执行，防手滑
setopt HIST_FIND_NO_DUPS       # ctrl+r 搜索时跳过重复项

export EDITOR="emacs -Q -nw -l ${HOME}/.emacs.d/init-mini.el"
export COLORTERM=truecolor
alias emacs-cli="$EDITOR"

# 加载p10k自定义配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==============================================================================
# 系统PATH与第三方工具初始化
# ==============================================================================
export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# ==============================================================================
# 常用别名与函数
# ==============================================================================
# 目录快捷跳转补位（zoxide 已提供 z / zi）
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# 建目录并进入
mkcd() { mkdir -p "$1" && cd "$1"; }
# 上一条命令忘加 sudo 时补执行
redo-sudo() { eval "sudo $(fc -ln -1)"; }

# 带颜色的 less / man
export LESS='--use-color -R'
export LESSHISTFILE=-               # 不留 less 查看历史
export MANPAGER="less --use-color -R"

# 系统/端口速查
alias df='df -h'
alias ports='ss -tulnp'
# 本地快速起一个文件服务器
alias serve='python3 -m http.server 8000'

# ---------- WSL 专属（自动检测，Windows/真机里不生效） ----------
if grep -qi microsoft /proc/version 2>/dev/null; then
    alias expl='explorer.exe .'          # 资源管理器打开当前目录
    alias clip='clip.exe'                # 管道进 Windows 剪贴板：cat file | clip
    alias open='explorer.exe'            # open xxx 用 Windows 打开文件/URL
fi

# ==============================================================================
# 外部函数库
# ==============================================================================
[[ -f ${HOME}/.zsh_funcs/compile_emacs.zsh ]] && source ${HOME}/.zsh_funcs/compile_emacs.zsh
[[ -f ${HOME}/.zsh_funcs/p.zsh ]] && source ${HOME}/.zsh_funcs/p.zsh

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

# 加载Zinit核心脚本与自身补全
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ==============================================================================
# ZSH 原生基础环境配置（删除冗余重复历史参数）
# ==============================================================================
# 编辑模式 Emacs 快捷键(Ctrl+a/e等)
bindkey -e
# 全局基础选项
setopt extendedglob nomatch notify
unsetopt beep

# 补全等待时显示一些点
COMPLETION_WAITING_DOTS="true"
# 开启错误自动提示
ENABLE_CORRECTION="true"
# oh-my-zsh中常用的插件
# key binding是通用的基础，不适合延迟加载
zinit lucid for OMZ::lib/key-bindings.zsh
zinit wait lucid for \
    OMZ::lib/git.zsh \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/completion.zsh \
    OMZ::lib/correction.zsh \
    OMZ::lib/history.zsh \
    OMZ::lib/theme-and-appearance.zsh \
    OMZ::plugins/git/git.plugin.zsh \
    OMZ::plugins/git-extras/git-extras.plugin.zsh

# 一些补全
zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions

# 用于优化下载的zinit插件
zinit light-mode for \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-rust

zinit wait"1" lucid as="completion" for \
    https://github.com/alacritty/alacritty/blob/master/extra/completions/_alacritty


# fast-syntax-highlighting 快速可靠的shell高亮
#     出于性能考虑，关闭了git的提示
# zsh-completions 一些自动补全
# zsh-autosuggestions fish一样的历史记录提示
#     配置了super+l / ctrl+l / ctrl+j作为选中的快捷键
zinit wait"0" lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
 atload"FAST_HIGHLIGHT[chroma-git]=0" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"_zsh_autosuggest_start;bindkey \"גּ \" autosuggest-accept; bindkey \"¬\" autosuggest-accept;bindkey \"^L\" autosuggest-accept; bindkey \"^J\" autosuggest-accept;bindkey \"גּl\" autosuggest-accept " \
    zsh-users/zsh-autosuggestions

# forgit git交互式工具
zinit wait"1" lucid  for \
      atinit"forgit_ignore='fgi'" \
      wfxr/forgit \
      hlissner/zsh-autopair

# fzf使用
zinit wait"1" lucid for \
    junegunn/fzf \
    as"completion" \
    https://github.com/junegunn/fzf/blob/master/shell/completion.zsh \
    https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh \
    Aloxaf/fzf-tab

#fzf-tab 配置
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
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

# 可能是最好的主题提示，在zsh下有极高的性能
zinit ice depth=1
zinit light romkatv/powerlevel10k
#历史纪录条目数量
HISTSIZE=1000000
#注销后保存的历史纪录条目数量
SAVEHIST=500000
#以附加的方式写入历史纪录
setopt INC_APPEND_HISTORY
#如果连续输入的命令相同，历史纪录中只保留一个
setopt HIST_IGNORE_DUPS
#为历史纪录中的命令添加时间戳
setopt EXTENDED_HISTORY
#启用 cd 命令的历史纪录，cd -[TAB]进入历史路径
setopt AUTO_PUSHD
#相同的历史路径只保留一个
setopt PUSHD_IGNORE_DUPS
#在命令前添加空格，不将此命令添加到纪录文件中
setopt HIST_IGNORE_SPACE
export EDITOR="emacs -Q -nw -l ${HOME}/.emacs.d/init-mini.el"

export COLORTERM=truecolor
export TERM=xterm-direct

alias emacs-cli="$EDITOR"

# 加载p10k自定义配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==============================================================================
# 系统PATH与第三方工具初始化（增加存在性判断，避免报错）
# ==============================================================================
# 本地二进制工具目录
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/clw/.bun/bin:$PATH"

# zoxide 智能目录跳转
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ==============================================================================
# 内置别名、自定义函数（简易版，复杂配置建议拆分到 ~/.config 下）
# ==============================================================================
# __git_aliased_command requires 1 argument
__git_aliased_command ()
{
        local word cmdline=$(__git config --get "alias.$1")
        for word in $cmdline; do
                case "$word" in
                \!gitk|gitk)
                        echo "gitk"
                        return
                        ;;
                \!*)        : shell command alias ;;
                -*)        : option ;;
                *=*)        : setting env ;;
                git)        : git itself ;;
                \(\))   : skip parens of shell function definition ;;
                {)        : skip start of shell helper function ;;
                :)        : skip null command ;;
                \'*)        : skip opening quote after sh -c ;;
                *)
                        echo "$word"
                        return
                esac
        done
		}
	       
# 代理开关函数：修复兼容性、增加端口数字校验，适配无ip命令环境
function proxy() {
    local PORT="${1:-7897}"
    # 参数校验
    if [[ "$2" != "off" ]] && ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "用法：proxy [端口数字] / proxy off"
        return 1
    fi

    if [[ "$2" == "off" ]]; then
        unset http_proxy https_proxy ALL_PROXY HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo "❌ 代理已关闭"
        return 0
    fi

     # 校验端口是否为数字且在有效范围内
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
        echo "用法：proxy [端口数字(1-65535)] / proxy off"
        return 1
    fi

    local gw="127.0.0.1"
    # 优先使用 ip route，fallback 到 netstat 或硬编码
    if command -v ip &>/dev/null; then
        gw=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    elif command -v netstat &>/dev/null; then
        gw=$(netstat -rn 2>/dev/null | awk '/default/ {print $2; exit}')
    fi

    export http_proxy="http://${gw}:${PORT}"
    export https_proxy="http://${gw}:${PORT}"
    export ALL_PROXY="socks5://${gw}:${PORT}"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    echo "✅ 代理已开启 (${gw}:${PORT})"
    echo "💡 测试: curl -I --proxy \$http_proxy https://www.baidu.com"
}

source ${HOME}/.zsh_funcs/compile_emacs.zsh

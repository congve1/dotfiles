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

# 超大容量历史记录配置（全局唯一，删除上方重复定义）
HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=500000
# 历史记录优化选项
setopt INC_APPEND_HISTORY        # 增量追加历史，不覆盖
setopt HIST_IGNORE_DUPS          # 连续重复命令只存一条
setopt EXTENDED_HISTORY          # 历史记录带时间戳
setopt AUTO_PUSHD                # cd自动压入目录栈，cd - 快速回退
setopt PUSHD_IGNORE_DUPS         # 目录栈去重
setopt HIST_IGNORE_SPACE         # 命令前空格不写入历史
setopt HIST_FIND_NO_DUPS         # 历史搜索自动跳过重复项
setopt HIST_NO_STORE             # !cmd 调用不写入历史文件
setopt SHARE_HISTORY             # 多终端窗口实时共享历史
setopt NO_BG_NICE                # 后台进程不降低优先级
setopt NO_HUP                    # 关闭终端不杀死后台任务

# 补全全局视觉配置
COMPLETION_WAITING_DOTS="true"
ENABLE_CORRECTION="true"
# 补全下拉菜单、分组、文件色彩美化
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# ==============================================================================
# Zinit 核心依赖 Annex（二进制下载/补丁/监控必备，优先加载）
# ==============================================================================
zinit light-mode for \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-rust

# ==============================================================================
# OMZ 基础库加载
# key-bindings 必须同步加载，其余基础库后台延迟0秒加载
# ==============================================================================
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

# ==============================================================================
# 核心增强插件 wait=0 后台加载（语法高亮/自动提示/括号配对）
# 修复：移除重复加载 zsh-completions，删除无效乱码unicode快捷键
# ==============================================================================
# 第三方补全库 阻塞式加载，保证补全稳定
zinit wait lucid atload="zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions

# 语法高亮 + 命令自动提示
zinit wait"0" lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
 atload"FAST_HIGHLIGHT[chroma-git]=0" \
    zdharma/fast-syntax-highlighting \
 atload"_zsh_autosuggest_start;bindkey \"^L\" autosuggest-accept; bindkey \"^J\" autosuggest-accept" \
    zsh-users/zsh-autosuggestions

# 自动括号配对、行内编辑增强
zinit wait="0" lucid light-mode for \
    hlissner/zsh-autopair \
    hchbaw/zce.zsh

# ==============================================================================
# 工具类插件 wait=1 延迟加载
# ==============================================================================
# alacritty 终端补全
zinit wait"1" lucid as="completion" for \
    https://github.com/alacritty/alacritty/blob/master/extra/completions/_alacritty

# forgit 交互式Git工具
zinit wait"1" lucid for \
 atinit"forgit_ignore='fgi'" \
    wfxr/forgit

# fzf 模糊搜索整套生态（合并分散三段，统一加载）
zinit wait"1" lucid pack"bgn-binary" for \
    junegunn/fzf \
    https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh \
    https://github.com/junegunn/fzf/blob/master/shell/completion.zsh

# sharkdp/fd
zinit ice as"command" from"gh-r" mv"fd*/fd -> fd" pick"fd"
zinit light sharkdp/fd
# sharkdp/bat
zinit ice as"command" from"gh-r" mv"bat*/bat -> bat" pick"bat"
zinit light sharkdp/bat
# ogham/exa, replacement for ls
# zinit ice wait"2" lucid from"gh-r" as"program" mv"bin/exa* -> exa"
zinit ice as"command" from"gh-r" mv"exa* -> exa" pick"bin/exa"
zinit light eza-community/eza
# BurntSushi/ripgrep
zinit ice from"gh-r" as"program" mv"ripgrep* -> ripgrep" pick"ripgrep/rg"
zinit light BurntSushi/ripgrep 
# junegunn/fzf-bin
zinit ice from"gh-r" as"program"
zinit light junegunn/fzf
# b4b4r07/httpstat
zinit ice as"program" mv"httpstat.sh -> httpstat" \
    pick"httpstat" atpull'!git reset --hard'
zinit light b4b4r07/httpstat
#sharkdp/hyperfine 命令行基准测试工具
zinit ice as"command" from"gh-r" mv"hyperfine*/hyperfine -> hyperfine" pick"sharkdp/hyperfine"
zinit light sharkdp/hyperfine
#chmln/sd sed 查找和替换
zinit ice as"command" from"gh-r" mv"sd* -> sd" pick"sd"
zinit light chmln/sd
#dandavison/delta git diff
zinit ice as"command" from"gh-r" mv"delta* -> delta" pick"delta"
zinit light dandavison/delta
# ogham/dog dns
zinit ice as"command" from"gh-r" mv"dog* -> dog" pick"bin/dog"
zinit light ogham/dog
# knqyf263/pet 命令描述,按描述查找
zinit ice as"command" from"gh-r" pick"pet"
zinit light knqyf263/pet

# ==============================================================================
# Powerlevel10k 主题（放到所有插件最后，避免色彩冲突）
# ==============================================================================
zinit ice depth=1
zinit light romkatv/powerlevel10k
# 加载p10k自定义配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==============================================================================
# 系统PATH与第三方工具初始化（增加存在性判断，避免报错）
# ==============================================================================
# 本地二进制工具目录
export PATH="$HOME/.local/bin:$PATH"

# zoxide 智能目录跳转
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ==============================================================================
# 内置别名、自定义函数（简易版，复杂配置建议拆分到 ~/.config 下）
# ==============================================================================
# 快捷SSH、编辑器、krb认证别名


# Git内部辅助函数，解析git别名真实底层命令
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



#!/bin/zsh
# ==============================
# Stow 配置管理工具函数
# ==============================

# 自定义 dotfiles 目录（根据你的实际路径修改）
export DOTFILES_DIR="${HOME}/dotfiles"

# 检查 Stow 是否安装
_check_stow() {
    if ! command -v stow &> /dev/null; then
        echo "❌ 未找到 stow，请先安装："
        echo "   Debian/Ubuntu: sudo apt install stow"
        echo "   Arch: sudo pacman -S stow"
        echo "   macOS: brew install stow"
        return 1
    fi
    return 0
}

# 安装指定包的配置文件
# 用法：stow_install <package_name>
stow_install() {
    _check_stow || return 1
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "❌ 用法：stow_install <package_name>"
        return 1
    fi
    if [[ ! -d "${DOTFILES_DIR}/${pkg}" ]]; then
        echo "❌ 包不存在：${DOTFILES_DIR}/${pkg}"
        return 1
    fi
    echo "📦 安装配置包：${pkg}"
    cd "${DOTFILES_DIR}" && stow -v "${pkg}"
    echo "✅ 完成！链接已创建到 ~"
}

# 卸载指定包的配置文件
# 用法：stow_remove <package_name>
stow_remove() {
    _check_stow || return 1
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "❌ 用法：stow_remove <package_name>"
        return 1
    fi
    echo "🗑️ 卸载配置包：${pkg}"
    cd "${DOTFILES_DIR}" && stow -v -D "${pkg}"
    echo "✅ 完成！符号链接已删除"
}

# 查看所有包的安装状态
# 用法：stow_status
stow_status() {
    _check_stow || return 1
    echo "📊 Stow 配置状态（${DOTFILES_DIR}）："
    cd "${DOTFILES_DIR}" && stow -v --no-folding .
}

# 备份现有配置到 dotfiles（避免覆盖）
# 用法：stow_backup <package_name> [target_path]
# 示例：stow_backup nvim ~/.config/nvim
stow_backup() {
    local pkg="$1"
    local target="${2:-${HOME}}"
    if [[ -z "$pkg" ]]; then
        echo "❌ 用法：stow_backup <package_name> [target_path]"
        return 1
    fi
    local backup_dir="${DOTFILES_DIR}/${pkg}"
    mkdir -p "${backup_dir}"
    echo "📦 备份 ${target} 到 ${backup_dir}"
    cp -r "${target%/}"/* "${backup_dir}/" 2>/dev/null || true
    echo "✅ 备份完成！"
}

# 同步 dotfiles 到远程仓库
# 用法：stow_sync [commit_message]
stow_sync() {
    local msg="${1:-"Update dotfiles $(date +%Y-%m-%d)"}"
    cd "${DOTFILES_DIR}" || return 1
    echo "🔄 同步 dotfiles 到远程..."
    git add .
    git commit -m "${msg}"
    git push
    echo "✅ 同步完成！"
}

# 更新所有已安装包的符号链接（修复断裂链接）
# 用法：stow_update
stow_update() {
    _check_stow || return 1
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "❌ 用法：stow_install <package_name>"
        return 1
    fi
    if [[ ! -d "${DOTFILES_DIR}/${pkg}" ]]; then
        echo "❌ 包不存在：${DOTFILES_DIR}/${pkg}"
        return 1
    fi
    echo "🔄 更新所有 Stow 包..."
    cd "${DOTFILES_DIR}" && stow -v -R "${pkg}"
    echo "✅ 所有包已刷新"
}

# 链接/更新 Emacs 配置到 ~/.emacs.d/
# 用法：stow_emacs [install|update]（默认：install）
stow_emacs() {
    local mode="${1:-install}"  # 默认模式为 install
    local DOTFILES_DIR="${HOME}/dotfiles"
    local EMACS_TARGET="${HOME}/.emacs.d"
    local BACKUP_DIR="${EMACS_TARGET}.bak_$(date +%Y%m%d_%H%M%S)"

    # 参数合法性检查
    if [[ "$mode" != "install" && "$mode" != "update" ]]; then
        echo "❌ 用法：stow_emacs [install|update]"
        echo "  默认：install（首次安装）"
        echo "  update：更新现有配置（重新链接）"
        return 1
    fi

    # 1. 检查 dotfiles 根目录
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Dotfiles 目录不存在: $DOTFILES_DIR"
        return 1
    fi

    # 2. 检查 Emacs 配置包
    if [[ ! -d "$DOTFILES_DIR/emacs" ]]; then
        echo "❌ Emacs 配置包不存在: $DOTFILES_DIR/emacs"
        echo "请确保目录结构为："
        echo "  $DOTFILES_DIR/emacs/"
        echo "  ├── init.el"
        echo "  ├── early-init.el"
        echo "  ├── init-mini.el"
        echo "  └── config/"
        return 1
    fi

    # --------------------------
    # Install 模式（首次安装）
    # --------------------------
    if [[ "$mode" == "install" ]]; then
        # 3. 创建目标目录（若不存在）
        if [[ ! -d "$EMACS_TARGET" ]]; then
            echo "📁 创建目标目录: $EMACS_TARGET"
            mkdir -p "$EMACS_TARGET"
        else
            # 4. 备份现有配置（避免覆盖）
            echo "📦 备份现有配置到: $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"

	    mv "${EMACS_TARGET}/*" "${BACKUP_DIR}/"
        fi

        # 5. 执行 Stow 链接
        echo "🔗 开始安装 Emacs 配置..."
        cd "$DOTFILES_DIR" || return 1
        if stow -v -t "$EMACS_TARGET" emacs; then
            echo "✅ Emacs 配置安装成功！"
            echo "💡 验证: ls -l $EMACS_TARGET"
        else
            echo "❌ Stow 链接失败，请检查错误信息。"
            return 1
        fi

    # --------------------------
    # Update 模式（更新配置）
    # --------------------------
    elif [[ "$mode" == "update" ]]; then
        echo "🔄 更新 Emacs 配置（重新链接）..."
        cd "$DOTFILES_DIR" || return 1
        # 使用 -R（restow）重新打包：先卸载旧链接，再创建新链接
        if stow -v -R -t "$EMACS_TARGET" emacs; then
            echo "✅ Emacs 配置更新成功！"
            echo "💡 验证: ls -l $EMACS_TARGET"
        else
            echo "❌ Stow 更新失败，请检查错误信息。"
            return 1
        fi
    fi
}

stow_install_all() {
    stow_install zsh
    stow_emacs
}

stow_update_all() {
    stow_update zsh
    stow_emacs update
}

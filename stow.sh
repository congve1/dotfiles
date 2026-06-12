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
    echo "🔄 更新所有 Stow 包..."
    cd "${DOTFILES_DIR}" && stow -v -R *
    echo "✅ 所有包已刷新"
}

# 编译 Emacs 的 zsh 工具函数（适配 WSL2 + TUI）
# 用法：compile_emacs [分支名] [安装前缀] [是否清理旧构建]
compile_emacs() {
    # 默认参数（匹配你提供的 feature/igc3 分支）
    local branch="${1:-feature/igc3}"
    local prefix="${2:-/usr/local}"
    local clean="${3:-true}"
    local src_dir="${HOME}/src/emacs"
    local repo_url="https://github.com/emacs-mirror/emacs.git"

    # --------------------------
    # 2. 准备源码目录（避免 WSL2 挂载盘性能问题）
    # --------------------------
    mkdir -p "$src_dir"
    cd "$src_dir" || return 1

    # --------------------------
    # 3. 克隆/更新仓库
    # --------------------------
    if [[ ! -d ".git" ]]; then
        echo "📥 克隆 Emacs 仓库（分支：$branch）..."
        git clone "$repo_url" . || return 1
    else
        echo "🔄 更新仓库..."
        git fetch origin || return 1
    fi

    # --------------------------
    # 4. 切换到目标分支
    # --------------------------
    echo "🌿 切换到分支：$branch"
    git checkout "$branch" || return 1
    git pull origin "$branch" || return 1

    # --------------------------
    # 5. 清理旧构建（可选）
    # --------------------------
    if [[ "$clean" == "true" ]]; then
        echo "🧹 清理旧构建文件..."
        rm -rf configure Makefile config.status src/config.h
        git clean -fdx
    fi

    # --------------------------
    # 6. 生成配置脚本
    # --------------------------
    echo "⚙️ 运行 autogen.sh..."
    ./autogen.sh || return 1

    # --------------------------
    # 7. 配置 TUI 专用选项（禁用 GUI）
    # --------------------------
    echo "🔧 配置编译选项（TUI 模式）..."
    ./configure \
        --prefix="$prefix" \
        --with-native-compilation=aot \  # 启用原生编译（加速 TUI）
	--with-tree-sitter

    # --------------------------
    # 8. 编译（使用所有 CPU 核心）
    # --------------------------
    echo "🏗️ 开始编译（使用 $(nproc) 个核心）..."
    make -j"$(nproc)" || return 1

    # --------------------------
    # 9. 安装到系统
    # --------------------------
    echo "📦 安装到 $prefix..."
    sudo make install || return 1

    # --------------------------
    # 10. 验证结果
    # --------------------------
    echo "✅ 编译完成！验证版本："
    emacs --version | head -n 1

    echo "\n💡 提示："
    echo "1. 若需 GUI 支持，移除 --without-x --without-gtk 选项"
    echo "2. 自定义路径示例：compile_emacs feature/igc3 ~/.local"
    echo "3. 清理旧构建：compile_emacs $branch $prefix true"
}

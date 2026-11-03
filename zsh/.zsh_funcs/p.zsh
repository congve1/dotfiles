# 代理开关：proxy [端口|off]
#   proxy        → 默认端口 7897 开启
#   proxy 8080   → 指定端口开启
#   proxy off    → 关闭（无需端口）
function proxy() {
    # 关闭：只看第一个参数，不需要端口
    if [[ "$1" == "off" ]]; then
        unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo "❌ 代理已关闭"
        return 0
    fi

    local PORT="${1:-7897}"
    # 校验端口是否为数字且在有效范围内
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
        echo "用法：proxy [端口(1-65535)|off]"
        echo "  proxy        # 默认 7897"
        echo "  proxy 8080   # 指定端口"
        echo "  proxy off    # 关闭代理"
        return 1
    fi

    local gw=""
    # 优先使用 ip route，fallback 到 netstat
    if command -v ip &>/dev/null; then
        gw=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    elif command -v netstat &>/dev/null; then
        gw=$(netstat -rn 2>/dev/null | awk '/default/ {print $2; exit}')
    fi
    # 两种方式都没取到网关时回退到本地回环，避免导出空地址
    [[ -n "$gw" ]] || gw="127.0.0.1"

    export http_proxy="http://${gw}:${PORT}"
    export https_proxy="http://${gw}:${PORT}"
    export all_proxy="socks5://${gw}:${PORT}"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export ALL_PROXY="$all_proxy"
    echo "✅ 代理已开启 (${gw}:${PORT})"
    echo "💡 测试: curl -I --proxy \$http_proxy https://www.baidu.com"
}

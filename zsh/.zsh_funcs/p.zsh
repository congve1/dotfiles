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

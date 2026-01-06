#!/bin/sh
# Hysteria2 容器专用一键部署脚本 (for Pterodactyl / lunes.host)
# 无需 root，无需 systemd，128MB 内存友好

set -e

# 颜色函数（兼容 sh）
red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
blue() { printf '\033[34m%s\033[0m\n' "$1"; }

WORK_DIR="/home/container"
cd "$WORK_DIR"

# 检测是否在容器中（简单判断）
if [ ! -f "/etc/alpine-release" ] && [ ! -f "/etc/os-release" ]; then
  yellow "⚠️  未检测到标准 Linux 环境，但仍继续（可能是 Alpine 容器）"
fi

# 检测架构
detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) red "❌ 不支持的 CPU 架构: $(uname -m)"; exit 1 ;;
  esac
}

# 生成随机密码
generate_password() {
  if command -v openssl >/dev/null; then
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-24
  else
    # 备用方案（Alpine 默认有 dd + base64）
    dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d "=+/" | cut -c1-24
  fi
}

# 下载 hysteria2
download_hysteria() {
  ARCH=$(detect_arch)
  VERSION="v2.6.5"  # 固定版本，避免 API 限制
  URL="https://github.com/apernet/hysteria/releases/download/app/${VERSION}/hysteria-linux-${ARCH}"
  
  green "📥 正在下载 Hysteria2 (${ARCH})..."
  if command -v curl >/dev/null; then
    curl -fsSLo hysteria "$URL"
  elif command -v wget >/dev/null; then
    wget -qO hysteria "$URL"
  else
    red "❌ 缺少 curl 或 wget，请联系主机商"
    exit 1
  fi
  chmod +x hysteria
  green "✅ Hysteria2 已下载到 $WORK_DIR/hysteria"
}

# 生成自签名证书（必须！）
generate_cert() {
  if [ ! -f cert.pem ] || [ ! -f key.pem ]; then
    green "🔐 正在生成自签名证书..."
    if command -v openssl >/dev/null; then
      openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -days 3650 -keyout key.pem -out cert.pem -subj "/CN=unused" >/dev/null 2>&1
    else
      red "❌ 容器中缺少 openssl，无法生成证书"
      red "请在面板中手动上传 cert.pem 和 key.pem 到 /home/container"
      exit 1
    fi
  else
    yellow "⚠️ 证书已存在，跳过生成"
  fi
}

# 用户输入（简化）
get_user_input() {
  echo
  blue "=== 配置 Hysteria2 ==="
  
  printf "请输入监听端口 (默认 3183): "
  read -r PORT
  PORT=${PORT:-3183}

  printf "请输入认证密码 (留空则生成随机): "
  read -r PASSWORD
  if [ -z "$PASSWORD" ]; then
    PASSWORD=$(generate_password)
    yellow "⚠️  已生成随机密码: $PASSWORD"
  fi

  # 伪装网站（可选，但推荐）
  printf "请输入伪装网址 (默认 www.microsoft.com): "
  read -r MASQ_URL
  MASQ_URL=${MASQ_URL:-"www.microsoft.com"}
  
  # 保存变量供后续使用
  export PORT PASSWORD MASQ_URL
}

# 生成 server.yaml（容器优化版）
generate_config() {
  cat > server.yaml <<EOF
listen: ":${PORT}"
tls:
  cert: "${WORK_DIR}/cert.pem"
  key: "${WORK_DIR}/key.pem"
  alpn:
    - "h3"
auth:
  type: password
  password: "${PASSWORD}"
masquerade:
  type: proxy
  proxy:
    url: ${MASQ_URL}
    rewriteHost: true
bandwidth:
  up: "100 mbps"
  down: "100 mbps"
quic:
  max_idle_timeout: "120s"
  keepalive_interval: "15s"
log:
  level: warn
udpIdleTimeout: 90s
disableUDP: false
EOF
  green "✅ 配置文件已生成: $WORK_DIR/server.yaml"
}

# 生成客户端信息
generate_client_info() {
  # 获取分配的域名（Pterodactyl 容器通常有 HOSTNAME 环境变量）
  SERVER_ADDR="${HOSTNAME:-$(hostname)}"
  if [ -z "$SERVER_ADDR" ] || [ "$SERVER_ADDR" = "localhost" ]; then
    # 如果无法获取，提示用户从面板查看
    SERVER_ADDR="YOUR.LUNES-HOST.DOMAIN.COM"  # 占位符
    yellow "⚠️  无法自动获取域名，请在 lunes.host 面板查看 'Allocations'"
  fi

  # 节点链接（自签名需 insecure=1）
  NEKO_LINK="hysteria2://${PASSWORD}@${SERVER_ADDR}:${PORT}/?insecure=1&sni=unused#Hysteria2"
  echo "$NEKO_LINK" > neko.txt

  # Clash Meta 配置
  cat > clash-meta.yaml <<EOF
proxies:
  - name: "Hysteria2"
    type: hysteria2
    server: ${SERVER_ADDR}
    port: ${PORT}
    password: "${PASSWORD}"
    sni: "unused"
    skip-cert-verify: true
EOF

  green "📄 客户端配置已生成:"
  echo "  节点链接: $WORK_DIR/neko.txt"
  echo "  Clash 配置: $WORK_DIR/clash-meta.yaml"
  echo
  blue "📌 重要提示:"
  echo "  1. 在 lunes.host 面板 → Network 查看你的实际域名（如 xxxx.lunes.host）"
  echo "  2. Startup Command 请设置为: sh -c \"./hysteria server -c server.yaml\""
  echo "  3. 重启服务器后即可连接"
}

# 主流程
main() {
  green "🚀 开始部署 Hysteria2（容器专用版）"
  
  download_hysteria
  generate_cert
  get_user_input
  generate_config
  generate_client_info
  
  green "🎉 部署完成！"
  echo
  blue "下一步操作:"
  echo "  1. 复制 $WORK_DIR/neko.txt 中的链接到客户端"
  echo "  2. 在面板设置 Startup Command 并 Restart"
}

# 运行
main

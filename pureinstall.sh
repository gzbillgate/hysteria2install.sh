#!/bin/bash
# Hysteria2 纯净版一键安装脚本
# 作者：stephchow
# 功能：仅从 GitHub 官方源安装，无第三方依赖，无后门

set -e

# 检查 root
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 用户运行此脚本（sudo -i）"
  exit 1
fi

# 颜色函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# 检测系统
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS=$ID
else
  red "❌ 无法识别操作系统"
  exit 1
fi

# 安装依赖
install_deps() {
  if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt update && apt install -y wget curl ca-certificates openssl jq net-tools
  elif [[ "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "rhel" ]]; then
    yum install -y epel-release
    yum install -y wget curl ca-certificates openssl jq net-tools
  else
    red "❌ 不支持的操作系统: $OS"
    exit 1
  fi
}

# 检测架构
detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
    *) red "❌ 不支持的 CPU 架构"; exit 1 ;;
  esac
}

# 获取最新版本（仅 GitHub API）
get_latest_version() {
  local version
  version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r '.tag_name')
  if [[ -z "$version" || "$version" == "null" ]]; then
    red "❌ 无法获取 Hysteria2 最新版本，请检查网络或 GitHub 访问"
    exit 1
  fi
  echo "$version"
}

# 创建工作目录
WORK_DIR="/opt/hysteria2"
mkdir -p "$WORK_DIR"

# 卸载函数
uninstall() {
  green "正在卸载 Hysteria2..."
  systemctl stop hysteria2 &>/dev/null || true
  systemctl disable hysteria2 &>/dev/null || true
  rm -f /etc/systemd/system/hysteria2.service
  rm -rf "$WORK_DIR"
  systemctl daemon-reload
  green "✅ Hysteria2 已完全卸载"
  exit 0
}

# 主安装流程
install() {
  install_deps
  detect_arch
  LATEST_VER=$(get_latest_version)
  green "🔍 检测到最新版本: $LATEST_VER"

  # 下载二进制
  DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/${LATEST_VER}/hysteria-linux-${ARCH}"
  green "📥 正在从 GitHub 下载: $DOWNLOAD_URL"
  if ! wget -q -O "$WORK_DIR/hysteria" "$DOWNLOAD_URL"; then
    red "❌ 下载失败，请检查网络或 GitHub 连接"
    exit 1
  fi
  chmod +x "$WORK_DIR/hysteria"

  # 用户输入
  echo
  blue "=== 配置 Hysteria2 ==="
  read -p "请输入监听端口 (默认 443): " PORT
  PORT=${PORT:-443}

  read -p "请输入认证密码 (留空则生成随机): " PASSWORD
  if [[ -z "$PASSWORD" ]]; then
    PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
    yellow "⚠️  已生成随机密码: $PASSWORD"
  fi

  read -p "是否使用自签名证书? (y/n, 默认 n): " USE_SELF_SIGNED
  if [[ "${USE_SELF_SIGNED,,}" == "y" ]]; then
    read -p "请输入用于证书的域名或 IP (例如: example.com): " CERT_NAME
    CERT_NAME=${CERT_NAME:-"localhost"}
    
    mkdir -p /etc/ssl/hysteria2
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
      -keyout /etc/ssl/hysteria2/private.key \
      -out /etc/ssl/hysteria2/cert.crt \
      -subj "/CN=$CERT_NAME" -days 3650
    
    chmod 600 /etc/ssl/hysteria2/private.key
    chmod 644 /etc/ssl/hysteria2/cert.crt
    
    TLS_CONFIG="
tls:
  cert: /etc/ssl/hysteria2/cert.crt
  key: /etc/ssl/hysteria2/private.key"
    SKIP_CERT_VERIFY="true"
    SNI="$CERT_NAME"
  else
    read -p "请输入你的已解析域名 (必须有效): " DOMAIN
    while [[ -z "$DOMAIN" ]]; do
      red "域名不能为空"
      read -p "请输入你的已解析域名: " DOMAIN
    done
    read -p "请输入邮箱 (用于 ACME, 默认 random@gmail.com): " EMAIL
    EMAIL=${EMAIL:-"random@gmail.com"}

    TLS_CONFIG="
acme:
  domains:
    - $DOMAIN
  email: $EMAIL"
    SKIP_CERT_VERIFY="false"
    SNI="$DOMAIN"
  fi

  # 伪装网站（可选）
  read -p "请输入伪装网址 (默认 https://www.bing.com): " MASQ_URL
  MASQ_URL=${MASQ_URL:-"https://www.bing.com"}

  # 生成 config.yaml
  cat > "$WORK_DIR/config.yaml" <<EOF
listen: :$PORT
auth:
  type: password
  password: $PASSWORD
masquerade:
  type: proxy
  proxy:
    url: $MASQ_URL
    rewriteHost: true
$TLS_CONFIG
bandwidth:
  up: 1 gbps
  down: 1 gbps
udpIdleTimeout: 90s
disableUDP: false
EOF

  # 创建 systemd 服务
  cat > /etc/systemd/system/hysteria2.service <<EOF
[Unit]
Description=Hysteria2 Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/hysteria server --config $WORK_DIR/config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable hysteria2
  systemctl start hysteria2

  # 生成客户端配置
  SERVER_IP=$(hostname -I | awk '{print $1}')
  if [[ -z "$SERVER_IP" ]]; then
    read -p "无法自动获取 IP，请手动输入服务器公网 IP: " SERVER_IP
  fi

  # Clash Meta 配置
  cat > "$WORK_DIR/clash-meta.yaml" <<EOF
port: 7890
socks-port: 7891
allow-lan: false
mode: rule
log-level: info
ipv6: false
external-controller: 127.0.0.1:9090

dns:
  enable: true
  listen: 0.0.0.0:53
  enhanced-mode: fake-ip
  nameserver:
    - 223.5.5.5
    - 8.8.8.8

proxies:
  - name: "Hysteria2"
    type: hysteria2
    server: $SERVER_IP
    port: $PORT
    password: "$PASSWORD"
    sni: "$SNI"
    skip-cert-verify: $SKIP_CERT_VERIFY

proxy-groups:
  - name: "🚀 节点选择"
    type: select
    proxies:
      - "Hysteria2"

rules:
  - MATCH,🚀 节点选择
EOF

  # Neko 节点链接
  if [[ "${USE_SELF_SIGNED,,}" == "y" ]]; then
    NEKO_LINK="hysteria2://$PASSWORD@$SERVER_IP:$PORT/?insecure=1&sni=$SNI#Hysteria2"
  else
    NEKO_LINK="hysteria2://$PASSWORD@$SERVER_IP:$PORT/?sni=$SNI#Hysteria2"
  fi
  echo "$NEKO_LINK" > "$WORK_DIR/neko.txt"

  green "✅ Hysteria2 安装成功！"
  echo
  blue "📌 重要信息："
  echo "  密码: $PASSWORD"
  echo "  端口: $PORT"
  echo "  SNI: $SNI"
  echo "  节点链接已保存至: $WORK_DIR/neko.txt"
  echo "  Clash 配置文件: $WORK_DIR/clash-meta.yaml"
  echo
  green "💡 请手动将节点链接导入客户端（如 NekoBox、Pharos Pro 等）"
}

# 主菜单
clear
echo "=================================="
echo "   Hysteria2 纯净安装脚本"
echo "   仅从 GitHub 官方源下载"
echo "=================================="
echo "1) 安装 Hysteria2"
echo "2) 卸载 Hysteria2"
echo "3) 退出"
read -p "请选择 (1/2/3): " CHOICE

case $CHOICE in
  1) install ;;
  2) uninstall ;;
  3) exit 0 ;;
  *) red "无效选项"; exit 1 ;;
esac

#!/bin/sh
# -*- coding: utf-8 -*-
#
# Hysteria2 容器一键部署脚本（专为 lunes.host / Alpine 容器优化）
# 作者: stephchow
# 更新时间: 2026-01-07
#
# 特性:
#   ✅ 无 systemd 依赖
#   ✅ 使用 hysteria 内置 gen-cert 生成证书
#   ✅ 自动架构检测 (amd64 / arm64)
#   ✅ 前台运行，符合容器规范
#   ✅ 仅依赖 wget 和 hysteria 二进制

set -e

PORT=${1:-29999}
SNI="www.microsoft.com"
ALPN="h3"

# 架构检测
case "$(uname -m)" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "❌ 不支持"; exit 1 ;;
esac

# 下载（无校验，因 Alpine 缺 sha256sum）
if [ ! -f hysteria ]; then
  echo "📥 下载 Hysteria2 ($ARCH)..."
  wget -qO hysteria "https://github.com/apernet/hysteria/releases/download/app/v2.6.5/hysteria-linux-$ARCH"
  chmod +x hysteria
fi

# 生成密码
PASSWORD=$(head -c 24 /dev/urandom | base64 | tr -d "=+/" | cut -c1-24)

# 写配置
cat > config.yaml <<EOF
listen: ":$PORT"
tls:
  cert: cert.pem
  key: key.pem
  alpn: ["$ALPN"]
auth:
  type: password
  password: "$PASSWORD"
quic:
  max_idle_timeout: "120s"
  keepalive_interval: "15s"
log:
  level: warn
EOF

# 生成自签名证书（用内置方式，避免 openssl）
./hysteria util gen-cert --domain "$SNI"

# 输出连接信息
IP=$(wget -qO- ifconfig.me/ip 2>/dev/null || echo "YOUR_IP")
echo
echo "🎉 部署完成！"
echo "🔑 密码: $PASSWORD"
echo "📱 链接: hysteria2://${PASSWORD}@${IP}:${PORT}?sni=${SNI}&alpn=${ALPN}&insecure=1"

# 前台运行
exec ./hysteria server -c config.yaml

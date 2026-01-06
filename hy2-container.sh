#!/bin/sh
# Hysteria2 容器专用一键部署脚本 (for Pterodactyl / lunes.host)
# 无需 root，无需 systemd，128MB 内存友好
#
# 作者: stephchow
# 版本: 1.0
# 更新日期: 2026-01-07
#
# 说明: 本脚本仅从 GitHub 官方源下载 Hysteria2，无第三方依赖，无后门。

#!/bin/sh
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

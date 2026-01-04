# Hysteria2 纯净一键安装脚本

> ✅ 安全 · 无后门 · 无第三方依赖 · 仅从 GitHub 官方源下载  
> 🛡️ 不收集 IP · 不连接非必要服务 · 私钥权限严格限制

这是一个为 **Hysteria2** 服务端设计的纯净版一键安装脚本，适用于 Ubuntu、Debian、CentOS 等主流 Linux 发行版。脚本完全本地运行，所有组件均从 [apernet/hysteria](https://github.com/apernet/hysteria) 官方仓库下载，无任何隐藏行为。

---

## 📥 使用方法

1.下载并运行脚本

wget -O hy2.sh https://raw.githubusercontent.com/gzbillgate/hysteria2-chow/refs/heads/main/pureinstall.sh

chmod +x hy2.sh

./hy2.sh

2. 按提示输入配置

监听端口（默认 443）

认证密码（可留空自动生成）

选择证书方式（自签名 或 ACME 域名）

伪装网址（如 https://www.bing.com）

3. 安装后文件位置

文件	路径

二进制	/opt/hysteria2/hysteria

配置	/opt/hysteria2/config.yaml

Clash 配置	/opt/hysteria2/clash-meta.yaml

节点链接	/opt/hysteria2/neko.txt

服务名	hysteria2

4. 服务管理（可选）

# 启动
systemctl start hysteria2
# 停止
systemctl stop hysteria2
# 查看状态
systemctl status hysteria2

# 查看日志
journalctl -u hysteria2 -f 

5.卸载

重新运行脚本，选择 “卸载 Hysteria2”，即可彻底清除所有文件与服务。

⚠️ 注意事项

若使用 ACME，请确保域名已正确解析到服务器 IP，且 80/443 端口开放。
自签名证书需在客户端开启 skip-cert-verify（脚本已自动处理）。
防火墙/安全组请放行所选端口（TCP/UDP）。

✅ 安全保证

本脚本严格遵循以下安全原则：

🔒 所有二进制文件 仅从 https://github.com/apernet/hysteria 下载

🚫 无任何 wget/curl 请求非 GitHub 域名（如 ip-api、短链、统计接口等）

🌐 不自动获取或上报服务器公网 IP

🔑 TLS 私钥权限设为 600（仅 root 可读写），绝不使用 777

🧹 无隐藏服务、无后门命令、无多余依赖

脚本逻辑完全透明，欢迎任何人审计源码。


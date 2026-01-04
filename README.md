# Hysteria2 纯净一键安装脚本

> ✅ 安全 · 无后门 · 无第三方依赖 · 仅从 GitHub 官方源下载  
> 🛡️ 不收集 IP · 不连接非必要服务 · 私钥权限严格限制

这是一个为 **Hysteria2** 服务端设计的纯净版一键安装脚本，适用于 Ubuntu、Debian、CentOS 等主流 Linux 发行版。脚本完全本地运行，所有组件均从 [apernet/hysteria](https://github.com/apernet/hysteria) 官方仓库下载，无任何隐藏行为。

---

## 📥 使用方法

### 1. 保存脚本
```bash
nano hysteria2-pure-install.sh
# 粘贴脚本内容，按 Ctrl+O 保存，Ctrl+X 退出
2. 赋予执行权限
chmod +x hysteria2-pure-install.sh
以 root 用户运行
./hysteria2-pure-install.sh
4. 按提示操作
输入监听端口（默认 443）
设置认证密码（可留空，自动随机生成）
选择证书方式：
自签名证书（适合测试或 IP 直连）
ACME 自动申请（需已解析的有效域名）
配置伪装网址（如 https://www.bing.com）
脚本将自动完成安装、配置与服务注册。
安装后文件位置
文件	路径
二进制程序	/opt/hysteria2/hysteria
服务端配置文件	/opt/hysteria2/config.yaml
Clash Meta 配置	/opt/hysteria2/clash-meta.yaml
节点链接（NekoBox 等）	/opt/hysteria2/neko.txt
Systemd 服务名	hysteria2
✅ 安全保证
本脚本严格遵循以下安全原则：

🔒 所有二进制文件 仅从 https://github.com/apernet/hysteria 下载
🚫 无任何 wget/curl 请求非 GitHub 域名（如 ip-api、短链、统计接口等）
🌐 不自动获取或上报服务器公网 IP
🔑 TLS 私钥权限设为 600（仅 root 可读写），绝不使用 777
🧹 无隐藏服务、无后门命令、无多余依赖
脚本逻辑完全透明，欢迎任何人审计源码。

🔧 服务管理（可选）
安装完成后，可通过 systemd 管理服务：

Bash
编辑
systemctl start hysteria2    # 启动服务
systemctl stop hysteria2     # 停止服务
systemctl restart hysteria2  # 重启服务
systemctl status hysteria2   # 查看运行状态
journalctl -u hysteria2 -f   # 实时查看日志
💡 注意：请确保防火墙或云服务商安全组已放行所选端口的 TCP 和 UDP 流量。

🗑️ 卸载
重新运行脚本，选择 “卸载 Hysteria2”，即可彻底清除：

二进制文件
配置与证书
systemd 服务单元
无残留，干净利落。

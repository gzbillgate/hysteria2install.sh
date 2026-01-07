# 专为 容器环境（如 lunes.host） 设计的轻量版 Hysteria2 部署脚本，它不需要 systemd、不依赖 openssl、无 SHA256 校验、无交互式输入，直接前台运行，非常适合在 Alpine Linux 容器中一键部署

> ✅ 安全 · 无后门 · 无第三方依赖 · 仅从 GitHub 官方源下载  
> 🛡️ 不收集 IP · 不连接非必要服务 · 私钥权限严格限制

---

## 一键部署命令

```
curl -fsSL https://raw.githubusercontent.com/gzbillgate/hysteria2-chow/refs/heads/main/hy2-container.sh | sh -s 29999

```
# 默认端口是29999，也可以自定义端口，比如你的服务器端口为3183

```
curl -fsSL https://raw.githubusercontent.com/gzbillgate/hysteria2-chow/refs/heads/main/hy2-container.sh | sh -s 3183

```





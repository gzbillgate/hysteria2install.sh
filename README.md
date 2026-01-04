保存脚本：
Bash
编辑
nano hysteria2-pure-install.sh
# 粘贴上述内容，保存退出
赋予执行权限：
Bash
编辑
chmod +x hysteria2-pure-install.sh
以 root 运行：
Bash
编辑
./hysteria2-pure-install.sh
按提示操作（输入端口、密码、域名等）
📁 安装后文件位置
文件	路径
二进制	/opt/hysteria2/hysteria
配置	/opt/hysteria2/config.yaml
Clash 配置	/opt/hysteria2/clash-meta.yaml
节点链接	/opt/hysteria2/neko.txt
服务名	hysteria2
✅ 安全保证
所有下载均来自 github.com/apernet/hysteria
无任何 wget/curl 到非 GitHub 域名
无自动 IP 上报
无私钥 777 权限
无隐藏服务或后门命令

#!/bin/bash
# 通用 socks5 安装脚本 适用于 CentOS Stream 9 / Debian 12
# 自定义端口与账号密码：bash install_sk5.sh <port> <user> <pass>

PORT=${1:-18801}
USER=${2:-888}
PASS=${3:-888}

set -e

if [[ -f /etc/redhat-release ]]; then
    PKG="dnf"
else
    PKG="apt"
fi

echo "[+] Installing dependencies..."
if [ "$PKG" == "apt" ]; then
    apt update -y && apt install -y curl wget tar systemd
else
    dnf install -y curl wget tar systemd
fi

mkdir -p /usr/local/sk5
cd /usr/local/sk5

echo "[+] Downloading socks5 binary..."
curl -L -o brook.tar.gz https://github.com/txthinking/brook/releases/latest/download/brook_linux_amd64.tar.gz
tar -zxvf brook.tar.gz --strip-components=1
chmod +x brook

# 创建启动脚本
cat > /usr/local/sk5/run.sh <<EOF
#!/bin/bash
/usr/local/sk5/brook socks5 -l 0.0.0.0:${PORT} -u ${USER} -p ${PASS}
EOF
chmod +x /usr/local/sk5/run.sh

# 创建 systemd 服务
cat > /etc/systemd/system/sk5.service <<EOF
[Unit]
Description=Simple Socks5 Proxy (sk5)
After=network.target

[Service]
ExecStart=/usr/local/sk5/run.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now sk5

IP=$(curl -s ipv4.ip.sb || curl -s ifconfig.me)
echo "======================================="
echo "✅ Socks5 安装成功！"
echo "地址: ${IP}"
echo "端口: ${PORT}"
echo "用户名: ${USER}"
echo "密码: ${PASS}"
echo "服务名: sk5"
echo "======================================="

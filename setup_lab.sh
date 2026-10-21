#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "請使用 sudo 執行此腳本"
  exit 1
fi

echo "開始執行基礎安全配置與 GPU 驅動安裝..."
export DEBIAN_FRONTEND=noninteractive
mkdir -p /etc/needrestart/conf.d
echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/99-autorestart.conf 2>/dev/null || true

timedatectl set-timezone Asia/Taipei

# 1. 系統更新與基礎工具
echo "-> 更新系統與安裝工具..."
apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt-get install -y curl wget vim htop ufw fail2ban unattended-upgrades ubuntu-drivers-common

# 2. 自動偵測並安裝 NVIDIA GPU 驅動
echo "-> 正在自動安裝適用的 NVIDIA GPU 驅動程式 (這需要一些時間)..."
ubuntu-drivers autoinstall

# 3. UFW 防火牆
echo "-> 設定 UFW 防火牆..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

# 4. Fail2ban
echo "-> 配置 Fail2ban..."
cat <<EOF > /etc/fail2ban/jail.d/99-custom-sshd.local
[sshd]
enabled = true
port = 22
backend = systemd
maxretry = 3
bantime = 3600
findtime = 600
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

# 5. SSH 安全強化 (禁用密碼與 Root)
echo "-> 強化 SSH 設定檔..."
cat <<EOF > /etc/ssh/sshd_config.d/99-security-hardening.conf
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
EOF
systemctl restart ssh

echo "==========================================================="
echo "✅ 伺服器配置完成！"
echo "⚠️ GPU 驅動已安裝，請務必重新開機 (sudo reboot) 讓核心載入驅動。"
echo "==========================================================="
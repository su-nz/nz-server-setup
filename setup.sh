#!/bin/bash

# =================================================================
# Ubuntu Server 初始化腳本
# 功能：安裝基礎工具、Tailscale、設定時區、配置自動更新
# =================================================================

set -e # 遇到錯誤立即停止執行

# 1. 基礎設定
export DEBIAN_FRONTEND=noninteractive
USER_GITHUB="su-nz"
REPO_NAME="nz-server-setup"

echo "🚀 [1/6] 更新系統套件索引..."
sudo apt update && sudo apt upgrade -y

echo "📦 [2/6] 安裝必備工具..."
sudo apt install -y curl wget git vim software-properties-common build-essential \
  htop net-tools tmux fail2ban ufw tree unzip

echo "🐳 [3/6] 安裝 Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh
# 將當前用戶加入 docker 群組
sudo usermod -aG docker $USER
echo "⚠️  Docker 已安裝，需重新登入才能使用（或執行: newgrp docker）"

echo "🔒 [4/6] 配置防火牆與防暴力破解..."
sudo systemctl enable ufw && sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp && sudo ufw enable -y
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
echo "✓ 防火牆已啟用，SSH(22) 開放"

echo "🌐 [5/6] 安裝 Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "🕒 [6/6] 設定時區為 Asia/Taipei..."
sudo timedatectl set-timezone Asia/Taipei

echo "📅 下載維護腳本並設定排程..."
# 下載 update.sh 到系統指令目錄
sudo curl -o /usr/local/bin/update.sh "https://raw.githubusercontent.com/${USER_GITHUB}/${REPO_NAME}/main/update.sh"
sudo chmod +x /usr/local/bin/update.sh

# 寫入 Crontab 排程 (每天凌晨 04:00 執行)
(sudo crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/update.sh") | sudo crontab -

echo "------------------------------------------------------"
echo "✅ 初始化完成！"
echo "👉 請執行 'sudo tailscale up' 來登入你的 Tailscale 網路。"
echo "👉 自動更新日誌將記錄於: /var/log/server_maintenance.log"
echo "------------------------------------------------------"
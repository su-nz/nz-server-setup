#!/bin/bash

# =================================================================
# Ubuntu Server 初始化腳本（互動式版本）
# 功能：安裝基礎工具、Tailscale、設定時區、配置自動更新
# =================================================================

set -e # 遇到錯誤立即停止執行

# 基礎設定
export DEBIAN_FRONTEND=noninteractive
USER_GITHUB="su-nz"
REPO_NAME="nz-server-setup"

# 初始化安裝選項（預設全部為 false）
INSTALL_SYSTEM_UPDATE=false
INSTALL_BASIC_TOOLS=false
INSTALL_DOCKER=false
INSTALL_FIREWALL=false
INSTALL_TAILSCALE=false
INSTALL_OPENVPN=false
INSTALL_TIMEZONE=false
INSTALL_MAINTENANCE=false

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =================================================================
# 主選單
# =================================================================
clear
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Ubuntu Server 初始化安裝程式${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "請選擇安裝模式："
echo "  1) 自動安裝全部項目"
echo "  2) 手動選擇安裝項目"
echo ""
read -p "請輸入選項 [1-2]: " mode_choice

if [[ "$mode_choice" == "1" ]]; then
    # 全部安裝
    INSTALL_SYSTEM_UPDATE=true
    INSTALL_BASIC_TOOLS=true
    INSTALL_DOCKER=true
    INSTALL_FIREWALL=true
    INSTALL_TAILSCALE=true
    INSTALL_OPENVPN=true
    INSTALL_TIMEZONE=true
    INSTALL_MAINTENANCE=true
elif [[ "$mode_choice" == "2" ]]; then
    # 手動選擇
    echo ""
    echo -e "${YELLOW}請選擇要安裝的項目（輸入 y/n）：${NC}"
    echo ""
    
    read -p "📦 更新系統套件？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_SYSTEM_UPDATE=true
    
    read -p "🛠️  安裝基礎工具（curl, git, vim, htop 等）？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_BASIC_TOOLS=true
    
    read -p "🐳 安裝 Docker？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_DOCKER=true
    
    read -p "🔒 配置防火牆（UFW + Fail2ban）？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_FIREWALL=true
    
    read -p "🌐 安裝 Tailscale VPN？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_TAILSCALE=true
    
    read -p "� 安裝 OpenVPN Server？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_OPENVPN=true
    
    read -p "�🕒 設定時區為 Asia/Taipei？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_TIMEZONE=true
    
    read -p "📅 下載維護腳本並設定自動更新排程？ [y/n]: " choice
    [[ "$choice" == "y" ]] && INSTALL_MAINTENANCE=true
else
    echo "無效的選項，程式退出。"
    exit 1
fi

# =================================================================
# 顯示安裝清單並確認
# =================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  即將安裝以下項目：${NC}"
echo -e "${GREEN}============================================${NC}"

install_count=0
[[ "$INSTALL_SYSTEM_UPDATE" == true ]] && echo "  ✓ 更新系統套件" && ((install_count++)) || true
[[ "$INSTALL_BASIC_TOOLS" == true ]] && echo "  ✓ 基礎工具套件" && ((install_count++)) || true
[[ "$INSTALL_DOCKER" == true ]] && echo "  ✓ Docker" && ((install_count++)) || true
[[ "$INSTALL_FIREWALL" == true ]] && echo "  ✓ 防火牆設定（UFW + Fail2ban）" && ((install_count++)) || true
[[ "$INSTALL_TAILSCALE" == true ]] && echo "  ✓ Tailscale VPN" && ((install_count++)) || true
[[ "$INSTALL_OPENVPN" == true ]] && echo "  ✓ OpenVPN Server" && ((install_count++)) || true
[[ "$INSTALL_TIMEZONE" == true ]] && echo "  ✓ 時區設定（Asia/Taipei）" && ((install_count++)) || true
[[ "$INSTALL_MAINTENANCE" == true ]] && echo "  ✓ 維護腳本與自動更新排程" && ((install_count++)) || true

if [[ $install_count -eq 0 ]]; then
    echo "  ⚠️  未選擇任何安裝項目"
    echo ""
    echo "程式退出。"
    exit 0
fi

echo -e "${GREEN}============================================${NC}"
echo ""
read -p "確定要開始安裝嗎？ [y/n]: " confirm

if [[ "$confirm" != "y" ]]; then
    echo "取消安裝。"
    exit 0
fi

# =================================================================
# 開始安裝
# =================================================================
echo ""
echo -e "${BLUE}🚀 開始安裝...${NC}"
echo ""

step=1

if [[ "$INSTALL_SYSTEM_UPDATE" == true ]]; then
    echo "🚀 [$step] 更新系統套件索引..."
    sudo apt update && sudo apt upgrade -y
    step=$((step + 1))
fi

if [[ "$INSTALL_BASIC_TOOLS" == true ]]; then
    echo "📦 [$step] 安裝必備工具..."
    sudo apt install -y curl wget git vim software-properties-common build-essential \
      htop net-tools tmux fail2ban ufw tree unzip traceroute
    step=$((step + 1))
fi

if [[ "$INSTALL_DOCKER" == true ]]; then
    echo "🐳 [$step] 安裝 Docker..."
    echo "   ⏳ 從官方來源下載安裝腳本..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    echo "   ✓ 下載完成，開始執行安裝..."
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Docker 已安裝，需重新登入才能使用（或執行: newgrp docker）"
    step=$((step + 1))
fi

if [[ "$INSTALL_FIREWALL" == true ]]; then
    echo "🔒 [$step] 配置防火牆與防暴力破解..."
    sudo systemctl enable ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw --force-enable
    sudo systemctl enable fail2ban && sudo systemctl start fail2ban
    echo "✓ 防火牆已啟用，SSH(22) 開放"
    step=$((step + 1))
fi

if [[ "$INSTALL_TAILSCALE" == true ]]; then
    echo "🌐 [$step] 安裝 Tailscale..."
    echo "   ⏳ 從官方來源下載安裝腳本..."
    curl -fsSL https://tailscale.com/install.sh -o tailscale-install.sh
    echo "   ✓ 下載完成，開始執行安裝..."
    sudo sh tailscale-install.sh
    rm tailscale-install.sh
    step=$((step + 1))
fi

if [[ "$INSTALL_OPENVPN" == true ]]; then
    echo "🔐 [$step] 安裝 OpenVPN Server..."
    echo "   ⏳ 從 GitHub 官方來源下載安裝腳本 (angristan/openvpn-install)..."
    # 使用官方 GitHub 完整 URL
    wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -O openvpn-install.sh
    chmod +x openvpn-install.sh
    echo "   ✓ OpenVPN 安裝腳本已下載"
    echo "⚠️  請執行 'sudo ./openvpn-install.sh' 來完成 OpenVPN 設定"
    echo "⚠️  安裝後記得開放 UDP 1194 端口: sudo ufw allow 1194/udp"
    step=$((step + 1))
fi

if [[ "$INSTALL_TIMEZONE" == true ]]; then
    echo "🕒 [$step] 設定時區為 Asia/Taipei..."
    sudo timedatectl set-timezone Asia/Taipei
    step=$((step + 1))
fi

if [[ "$INSTALL_MAINTENANCE" == true ]]; then
    echo "📅 [$step] 下載維護腳本並設定排程..."
    sudo curl -o /usr/local/bin/update.sh "https://raw.githubusercontent.com/${USER_GITHUB}/${REPO_NAME}/main/update.sh"
    sudo chmod +x /usr/local/bin/update.sh
    (sudo crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/update.sh") | sudo crontab -
    step=$((step + 1))
fi

# =================================================================
# 完成訊息
# =================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ 安裝完成！${NC}"
echo -e "${GREEN}============================================${NC}"

[[ "$INSTALL_TAILSCALE" == true ]] && echo "👉 請執行 'sudo tailscale up' 來登入你的 Tailscale 網路。"
[[ "$INSTALL_OPENVPN" == true ]] && echo "👉 請執行 'sudo ./openvpn-install.sh' 來完成 OpenVPN Server 設定。"
[[ "$INSTALL_MAINTENANCE" == true ]] && echo "👉 自動更新日誌將記錄於: /var/log/server_maintenance.log"

echo -e "${GREEN}============================================${NC}"

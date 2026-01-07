#!/bin/bash

# =================================================================
# Ubuntu Server 初始化腳本（互動式版本）
# 功能：安裝基礎工具、Tailscale、設定時區、配置自動更新
# =================================================================

# 基礎設定
export DEBIAN_FRONTEND=noninteractive
USER_GITHUB="su-nz"
REPO_NAME="nz-server-setup"

# 錯誤追蹤陣列
declare -a ERRORS=()
declare -a WARNINGS=()

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
    if ! sudo apt update && sudo apt upgrade -y; then
        ERRORS+=("[系統更新] 套件更新失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_BASIC_TOOLS" == true ]]; then
    echo "📦 [$step] 安裝必備工具..."
    if ! sudo apt install -y curl wget git vim software-properties-common build-essential \
      htop net-tools tmux fail2ban ufw tree unzip traceroute; then
        ERRORS+=("[基礎工具] 安裝失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_DOCKER" == true ]]; then
    echo "🐳 [$step] 安裝 Docker..."
    echo "   ⏳ 從官方來源下載安裝腳本..."
    if curl -fsSL https://get.docker.com -o get-docker.sh; then
        echo "   ✓ 下載完成，開始執行安裝..."
        if sudo sh get-docker.sh; then
            rm get-docker.sh
            sudo usermod -aG docker $USER
            echo "⚠️  Docker 已安裝，需重新登入才能使用（或執行: newgrp docker）"
        else
            ERRORS+=("[Docker] 安裝失敗")
            rm -f get-docker.sh
        fi
    else
        ERRORS+=("[Docker] 下載安裝腳本失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_FIREWALL" == true ]]; then
    echo "🔒 [$step] 配置防火牆與防暴力破解..."
    firewall_error=false
    sudo systemctl enable ufw || firewall_error=true
    sudo ufw default deny incoming || firewall_error=true
    sudo ufw default allow outgoing || firewall_error=true
    sudo ufw allow 22/tcp || firewall_error=true
    echo "y" | sudo ufw enable || firewall_error=true
    
    if ! sudo systemctl enable fail2ban || ! sudo systemctl start fail2ban; then
        WARNINGS+=("[Fail2ban] 啟動失敗，請手動檢查")
    fi
    
    if [[ "$firewall_error" == true ]]; then
        ERRORS+=("[防火牆] UFW 配置失敗")
    else
        echo "✓ 防火牆已啟用，SSH(22) 開放"
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_TAILSCALE" == true ]]; then
    echo "🌐 [$step] 安裝 Tailscale..."
    echo "   ⏳ 從官方來源下載安裝腳本..."
    if curl -fsSL https://tailscale.com/install.sh -o tailscale-install.sh; then
        echo "   ✓ 下載完成，開始執行安裝..."
        if sudo sh tailscale-install.sh; then
            rm tailscale-install.sh
        else
            ERRORS+=("[Tailscale] 安裝失敗")
            rm -f tailscale-install.sh
        fi
    else
        ERRORS+=("[Tailscale] 下載安裝腳本失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_OPENVPN" == true ]]; then
    echo "🔐 [$step] 安裝 OpenVPN Server..."
    echo "   ⏳ 從 GitHub 官方來源下載安裝腳本 (angristan/openvpn-install)..."
    # 使用官方 GitHub 完整 URL
    if wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -O openvpn-install.sh; then
        chmod +x openvpn-install.sh
        echo "   ✓ OpenVPN 安裝腳本已下載"
        echo "⚠️  請執行 'sudo ./openvpn-install.sh' 來完成 OpenVPN 設定"
        echo "⚠️  安裝後記得開放 UDP 1194 端口: sudo ufw allow 1194/udp"
    else
        ERRORS+=("[OpenVPN] 下載安裝腳本失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_TIMEZONE" == true ]]; then
    echo "🕒 [$step] 設定時區為 Asia/Taipei..."
    if ! sudo timedatectl set-timezone Asia/Taipei; then
        ERRORS+=("[時區設定] 設定失敗")
    fi
    step=$((step + 1))
fi

if [[ "$INSTALL_MAINTENANCE" == true ]]; then
    echo "📅 [$step] 下載維護腳本並設定排程..."
    if sudo curl -o /usr/local/bin/update.sh "https://raw.githubusercontent.com/${USER_GITHUB}/${REPO_NAME}/main/update.sh"; then
        if sudo chmod +x /usr/local/bin/update.sh; then
            if ! (sudo crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/update.sh") | sudo crontab -; then
                WARNINGS+=("[維護排程] Crontab 設定失敗，請手動設定")
            fi
        else
            ERRORS+=("[維護腳本] 設定執行權限失敗")
        fi
    else
        ERRORS+=("[維護腳本] 下載失敗")
    fi
    step=$((step + 1))
fi

# =================================================================
# 完成訊息
# =================================================================
echo ""

# 顯示錯誤和警告
if [[ ${#ERRORS[@]} -gt 0 ]] || [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${YELLOW}⚠️  安裝完成，但有一些問題需要注意${NC}"
    echo -e "${YELLOW}============================================${NC}"
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo -e "${RED}"
        echo "❌ 錯誤："
        for error in "${ERRORS[@]}"; do
            echo "  - $error"
        done
        echo -e "${NC}"
    fi
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}"
        echo "⚠️  警告："
        for warning in "${WARNINGS[@]}"; do
            echo "  - $warning"
        done
        echo -e "${NC}"
    fi
    
    echo -e "${YELLOW}============================================${NC}"
    echo ""
fi

echo -e "${GREEN}============================================${NC}"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ 安裝完成！${NC}"
else
    echo -e "${YELLOW}✅ 安裝部分完成${NC}"
fi
echo -e "${GREEN}============================================${NC}"

[[ "$INSTALL_TAILSCALE" == true ]] && echo "👉 請執行 'sudo tailscale up' 來登入你的 Tailscale 網路。"
[[ "$INSTALL_OPENVPN" == true ]] && echo "👉 請執行 'sudo ./openvpn-install.sh' 來完成 OpenVPN Server 設定。"
[[ "$INSTALL_MAINTENANCE" == true ]] && echo "👉 自動更新日誌將記錄於: /var/log/server_maintenance.log"

echo -e "${GREEN}============================================${NC}"

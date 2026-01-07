#!/bin/bash

# =================================================================
# Ubuntu Server 自動維護腳本
# 功能：自動更新套件、清理過期檔案、Docker 維護、記錄日誌
# =================================================================

# 檢查是否以 root 身份執行
if [ "$EUID" -ne 0 ]; then
   echo "❌ 此腳本需要 root 權限，請使用 sudo 執行"
   exit 1
fi

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

LOG_FILE="/var/log/server_maintenance.log"

# 確保日誌檔案存在並具備權限
touch $LOG_FILE

# 強制非互動模式，防止更新時卡住
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a  # 自動重啟服務

# 開始標記
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}🔧 系統維護開始於 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}============================================${NC}"
echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] 自動維護啟動 ---" >> $LOG_FILE

# =================================================================
# 執行更新序列
# =================================================================

echo -e "${YELLOW}📦 [1/6] 更新套件索引...${NC}"
{
    echo ">> [1/6] Updating package list..."
    apt-get update -y
} >> $LOG_FILE 2>&1
echo -e "${GREEN}   ✓ 完成${NC}"

echo -e "${YELLOW}⬆️  [2/6] 升級已安裝套件...${NC}"
{
    echo ">> [2/6] Upgrading packages..."
    apt-get upgrade -y
} >> $LOG_FILE 2>&1
echo -e "${GREEN}   ✓ 完成${NC}"

echo -e "${YELLOW}🚀 [3/6] 執行完整系統升級...${NC}"
{
    echo ">> [3/6] Dist-upgrading (kernel/distro updates)..."
    apt-get dist-upgrade -y
} >> $LOG_FILE 2>&1
echo -e "${GREEN}   ✓ 完成${NC}"

echo -e "${YELLOW}🧹 [4/6] 清理未使用的套件...${NC}"
{
    echo ">> [4/6] Cleaning up unused packages..."
    apt-get autoremove -y
    apt-get autoclean -y
} >> $LOG_FILE 2>&1
echo -e "${GREEN}   ✓ 完成${NC}"

echo -e "${YELLOW}🗑️  [5/6] 移除孤立的依賴套件...${NC}"
{
    echo ">> [5/6] Removing unused dependencies..."
    apt-get autoremove --purge -y
} >> $LOG_FILE 2>&1
echo -e "${GREEN}   ✓ 完成${NC}"

# =================================================================
# Docker 維護（如果已安裝）
# =================================================================
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 [6/6] 清理 Docker 資源...${NC}"
    {
        echo ">> [6/6] Docker cleanup..."
        # 清理未使用的映像、容器、網路和卷
        docker system prune -af --volumes
    } >> $LOG_FILE 2>&1
    echo -e "${GREEN}   ✓ 完成${NC}"
else
    echo -e "${YELLOW}⏭️  [6/6] 跳過 Docker 清理（未安裝）${NC}"
    echo ">> [6/6] Docker not installed, skipping cleanup" >> $LOG_FILE
fi

# =================================================================
# 完成標記
# =================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ 系統維護完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "📊 詳細日誌：${LOG_FILE}"
echo ""

echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] 維護任務完成 ---" >> $LOG_FILE
echo "================================================" >> $LOG_FILE
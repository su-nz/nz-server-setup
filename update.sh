#!/bin/bash

# =================================================================
# Ubuntu Server 自動維護腳本
# 功能：自動更新套件、清理過期檔案、記錄日誌
# =================================================================

# 檢查是否以 root 身份執行
if [ "$EUID" -ne 0 ]; then
   echo "❌ 此腳本需要 root 權限，請使用 sudo 執行"
   exit 1
fi

LOG_FILE="/var/log/server_maintenance.log"

# 確保日誌檔案存在並具備權限
touch $LOG_FILE

echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] 自動更新啟動 ---" >> $LOG_FILE

# 強制非互動模式，防止更新時卡住
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a  # 自動重啟服務

# 執行更新序列
{
    echo ">> Step 1: Updating package list..."
    apt-get update -y
    
    echo ">> Step 2: Upgrading packages..."
    apt-get upgrade -y
    
    echo ">> Step 3: Dist-upgrading (kernel/distro updates)..."
    apt-get dist-upgrade -y
    
    echo ">> Step 4: Cleaning up unused packages..."
    apt-get autoremove -y
    apt-get autoclean -y
    
    echo ">> Step 5: Removing unused dependencies..."
    apt-get autoremove --purge -y
} >> $LOG_FILE 2>&1

echo "--- [$(date '+%Y-%m-%d %H:%M:%S')] 更新任務完成 ---" >> $LOG_FILE
echo "------------------------------------------------" >> $LOG_FILE
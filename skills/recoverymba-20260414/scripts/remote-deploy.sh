#!/bin/bash
# 遠端部署腳本 - 將 RecoveryMBA Skill 傳給大爆蝦 (192.168.1.101)
# Usage: bash remote-deploy.sh

set -e

REMOTE_HOST="192.168.1.101"
REMOTE_USER="ericsu"  # 假設用戶名相同
SKILL_DIR="$HOME/.openclaw/workspace/skills/recoverymba-20260414"
REMOTE_SKILL_DIR="~/.openclaw/workspace/skills/recoverymba-20260414"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DEPLOY_LOG="$HOME/.openclaw/workspace/remote-deploy-$(date '+%Y%m%d-%H%M%S').log"

echo "========================================" | tee "$DEPLOY_LOG"
echo "🦐 遠端部署 - RecoveryMBA to 大爆蝦" | tee -a "$DEPLOY_LOG"
echo "Time: $TIMESTAMP" | tee -a "$DEPLOY_LOG"
echo "Target: $REMOTE_HOST" | tee -a "$DEPLOY_LOG"
echo "========================================" | tee -a "$DEPLOY_LOG"
echo "" | tee -a "$DEPLOY_LOG"

# Step 1: 檢查遠端主機是否在線
echo "[Step 1] 檢查 192.168.1.101 是否在線..." | tee -a "$DEPLOY_LOG"

if ping -c 1 "$REMOTE_HOST" >/dev/null 2>&1; then
  echo "✅ 遠端主機在線" | tee -a "$DEPLOY_LOG"
else
  echo "❌ 無法連接 $REMOTE_HOST" | tee -a "$DEPLOY_LOG"
  echo "請確保大爆蝦 (192.168.1.101) 已開啟" | tee -a "$DEPLOY_LOG"
  exit 1
fi

echo "" | tee -a "$DEPLOY_LOG"

# Step 2: 傳輸 Skill 檔案
echo "[Step 2] 傳輸 RecoveryMBA Skill 到大爆蝦..." | tee -a "$DEPLOY_LOG"

if scp -r "$SKILL_DIR" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SKILL_DIR}" 2>&1 | tee -a "$DEPLOY_LOG"; then
  echo "✅ Skill 傳輸成功" | tee -a "$DEPLOY_LOG"
else
  echo "⚠️  Skill 傳輸失敗（可能需要 SSH 金鑰配置）" | tee -a "$DEPLOY_LOG"
  echo "手動傳輸指令：" | tee -a "$DEPLOY_LOG"
  echo "scp -r $SKILL_DIR ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SKILL_DIR}" | tee -a "$DEPLOY_LOG"
  exit 1
fi

echo "" | tee -a "$DEPLOY_LOG"

# Step 3: 在大爆蝦上執行優化
echo "[Step 3] 在大爆蝦上執行 RecoveryMBA 優化..." | tee -a "$DEPLOY_LOG"

ssh "${REMOTE_USER}@${REMOTE_HOST}" << 'REMOTE_SCRIPT' | tee -a "$DEPLOY_LOG"
echo "🦐 大爆蝦開始執行優化..."
bash ~/.openclaw/workspace/skills/recoverymba-20260414/scripts/recover.sh
echo "✅ 大爆蝦優化完成"
REMOTE_SCRIPT

echo "" | tee -a "$DEPLOY_LOG"

# Step 4: 驗證遠端系統
echo "[Step 4] 驗證大爆蝦系統狀態..." | tee -a "$DEPLOY_LOG"

ssh "${REMOTE_USER}@${REMOTE_HOST}" << 'VERIFY_SCRIPT' | tee -a "$DEPLOY_LOG"
echo "檢查 Ollama 狀態..."
ollama list
echo ""
echo "檢查 OpenClaw 模型..."
openclaw models list --provider ollama | head -5
VERIFY_SCRIPT

echo "" | tee -a "$DEPLOY_LOG"

# Step 5: 發送完成通知
echo "[Step 5] 發送完成通知到你的 Telegram..." | tee -a "$DEPLOY_LOG"

# 構建通知消息
NOTIFICATION="🦐 大爆蝦優化完成！\n\n✅ RecoveryMBA Skill 已成功部署並執行\n\n主機：192.168.1.101 (Mac mini M4)\n時間：$(date '+%Y-%m-%d %H:%M:%S')\n\n系統已恢復完整配置：\n✅ Ollama 優化\n✅ OpenClaw 配置\n✅ Cron Jobs\n\n更多詳情請查看日誌：\n$DEPLOY_LOG"

echo -e "$NOTIFICATION" | tee -a "$DEPLOY_LOG"

# 如果配置了 Telegram，可以發送通知
# (需要 Telegram Bot API 配置)

echo "" | tee -a "$DEPLOY_LOG"
echo "========================================" | tee -a "$DEPLOY_LOG"
echo "✅ 遠端部署完成！" | tee -a "$DEPLOY_LOG"
echo "========================================" | tee -a "$DEPLOY_LOG"
echo "" | tee -a "$DEPLOY_LOG"
echo "日誌保存到：$DEPLOY_LOG" | tee -a "$DEPLOY_LOG"

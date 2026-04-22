#!/bin/bash
# 安全審計腳本 - 每 8 小時執行一次
# 檢查：可疑程序、日誌、異常連線、危險 skill

set -e

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_LOG="/Users/ericsu/.openclaw/workspace/security-audit.log"
ALERT_THRESHOLD=3

echo "[$TIMESTAMP] 開始安全審計..." >> "$AUDIT_LOG"
echo "" >> "$AUDIT_LOG"

# ==================== 1. 可疑程序檢查 ====================
echo "[1️⃣  可疑程序檢查]" >> "$AUDIT_LOG"

SUSPICIOUS_PROCS=$(ps aux | grep -E "curl.*telegram|wget.*token|nc|bash -i|perl|python -c" | grep -v grep | wc -l)

if [ "$SUSPICIOUS_PROCS" -gt 0 ]; then
  echo "⚠️  警告：發現 $SUSPICIOUS_PROCS 個可疑進程" >> "$AUDIT_LOG"
  ps aux | grep -E "curl.*telegram|wget.*token|nc|bash -i" | grep -v grep >> "$AUDIT_LOG"
else
  echo "✅ 無可疑進程" >> "$AUDIT_LOG"
fi

echo "" >> "$AUDIT_LOG"

# ==================== 2. 日誌可疑跡象檢查 ====================
echo "[2️⃣  日誌審計]" >> "$AUDIT_LOG"

# 檢查 getUpdates（Telegram 監控）
GETT_UPDATES=$(grep -r "getUpdates" ~/.openclaw/agents/main/sessions/ 2>/dev/null | wc -l || echo 0)
if [ "$GETT_UPDATES" -gt 0 ]; then
  echo "⚠️  警告：發現 getUpdates 請求 ($GETT_UPDATES 次)" >> "$AUDIT_LOG"
fi

# 檢查密碼/金鑰查詢
SECRET_QUERIES=$(grep -r "password\|apiKey\|secret\|token" ~/.openclaw/agents/main/sessions/ 2>/dev/null | grep -v "apiKey.*ollama" | wc -l || echo 0)
if [ "$SECRET_QUERIES" -gt 0 ]; then
  echo "⚠️  警告：發現 $SECRET_QUERIES 次密鑰查詢" >> "$AUDIT_LOG"
fi

# 檢查權限提升請求
PRIV_REQUESTS=$(grep -r "sudo\|root\|admin" ~/.openclaw/agents/main/sessions/ 2>/dev/null | wc -l || echo 0)
if [ "$PRIV_REQUESTS" -gt 0 ]; then
  echo "⚠️  警告：發現 $PRIV_REQUESTS 次權限提升要求" >> "$AUDIT_LOG"
fi

if [ "$GETT_UPDATES" -eq 0 ] && [ "$SECRET_QUERIES" -eq 0 ] && [ "$PRIV_REQUESTS" -eq 0 ]; then
  echo "✅ 日誌無可疑跡象" >> "$AUDIT_LOG"
fi

echo "" >> "$AUDIT_LOG"

# ==================== 3. 異常連線檢查 ====================
echo "[3️⃣  網路連線檢查]" >> "$AUDIT_LOG"

# 檢查外網連線（除了 Telegram/API）
EXTERNAL_CONN=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -v "127.0.0.1" | grep -v "api.telegram.org" | grep -v "api.openrouter.org" | grep -v "api.anthropic.com" | wc -l || echo 0)

if [ "$EXTERNAL_CONN" -gt 0 ]; then
  echo "⚠️  警告：發現 $EXTERNAL_CONN 個異常外網連線" >> "$AUDIT_LOG"
  netstat -an | grep ESTABLISHED | grep -v "127.0.0.1" >> "$AUDIT_LOG"
else
  echo "✅ 無異常外網連線" >> "$AUDIT_LOG"
fi

echo "" >> "$AUDIT_LOG"

# ==================== 4. 危險 Skill 檢查 ====================
echo "[4️⃣  Skill 安全檢查]" >> "$AUDIT_LOG"

DANGEROUS_SKILLS=$(find ~/.openclaw/workspace/skills -name "*.sh" -o -name "*.py" | while read skill; do
  if grep -q "rm\|dd\|mkfs\|sudo.*passwd\|chmod.*000" "$skill" 2>/dev/null; then
    echo "$skill"
  fi
done | wc -l || echo 0)

if [ "$DANGEROUS_SKILLS" -gt 0 ]; then
  echo "⚠️  警告：發現 $DANGEROUS_SKILLS 個包含危險操作的 skill" >> "$AUDIT_LOG"
  find ~/.openclaw/workspace/skills -name "*.sh" -o -name "*.py" | while read skill; do
    if grep -q "rm\|dd\|mkfs\|sudo.*passwd" "$skill" 2>/dev/null; then
      echo "  - $skill" >> "$AUDIT_LOG"
    fi
  done
else
  echo "✅ 無危險 Skill" >> "$AUDIT_LOG"
fi

echo "" >> "$AUDIT_LOG"

# ==================== 5. 總結 ====================
echo "[總結]" >> "$AUDIT_LOG"

ALERTS=$((SUSPICIOUS_PROCS + GETT_UPDATES + SECRET_QUERIES + PRIV_REQUESTS + EXTERNAL_CONN + DANGEROUS_SKILLS))

if [ "$ALERTS" -eq 0 ]; then
  echo "✅ 安全檢查完成：無異常發現" >> "$AUDIT_LOG"
  echo "安全等級：GREEN 🟢" >> "$AUDIT_LOG"
elif [ "$ALERTS" -lt "$ALERT_THRESHOLD" ]; then
  echo "⚠️  安全檢查完成：發現 $ALERTS 項警告" >> "$AUDIT_LOG"
  echo "安全等級：YELLOW 🟡" >> "$AUDIT_LOG"
else
  echo "🚨 安全檢查完成：發現 $ALERTS 項警告（超過閾值）" >> "$AUDIT_LOG"
  echo "安全等級：RED 🔴" >> "$AUDIT_LOG"
fi

echo "[$TIMESTAMP] 安全審計結束" >> "$AUDIT_LOG"
echo "========================================" >> "$AUDIT_LOG"
echo "" >> "$AUDIT_LOG"

# 如果警告數超過閾值，發送提醒
if [ "$ALERTS" -ge "$ALERT_THRESHOLD" ]; then
  echo "🚨 安全告警！發現 $ALERTS 項異常，請立即檢查：" >&2
  tail -50 "$AUDIT_LOG" | grep -E "⚠️|🚨" >&2
fi

#!/bin/bash
# 增強版安全審計腳本 - 自動記錄並拒絕可疑核准請求
# Usage: bash security-audit-enhanced.sh

set -e

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
AUDIT_LOG="/Users/ericsu/.openclaw/workspace/security-audit-enhanced.log"
SUSPICIOUS_APPROVALS="/Users/ericsu/.openclaw/workspace/suspicious-approvals.json"
ALERT_THRESHOLD=3

echo "[$TIMESTAMP] 開始增強版安全審計..." | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# ==================== 可疑模式定義 ====================
# 這些模式會被自動拒絕和記錄

SUSPICIOUS_PATTERNS=(
    "telegram"
    "getUpdates"
    "bot.*token"
    "api.*telegram"
    "offset"
    "curl.*telegram"
    "password"
    "apiKey"
    "secret"
    "rm.*-rf"
    "dd.*if="
    "mkfs"
    "sudo"
)

# ==================== 1. 檢查待決核准請求 ====================
echo "[1️⃣  檢查待決核准]" | tee -a "$AUDIT_LOG"

# 初始化可疑記錄
if [ ! -f "$SUSPICIOUS_APPROVALS" ]; then
    echo "{\"records\": [], \"lastChecked\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$SUSPICIOUS_APPROVALS"
fi

APPROVAL_COUNT=0
SUSPICIOUS_COUNT=0

# 檢查 OpenClaw 核准日誌（如果存在）
if [ -f "$HOME/.openclaw/exec-approvals.json" ]; then
    echo "📋 發現核准日誌，分析中..." | tee -a "$AUDIT_LOG"
    
    # 解析待決核准
    PENDING_APPROVALS=$(grep -o '"id":"[^"]*"' "$HOME/.openclaw/exec-approvals.json" 2>/dev/null || echo "")
    APPROVAL_COUNT=$(echo "$PENDING_APPROVALS" | wc -l)
    
    if [ "$APPROVAL_COUNT" -gt 0 ]; then
        echo "✅ 發現 $APPROVAL_COUNT 個待決核准" | tee -a "$AUDIT_LOG"
        
        # 檢查每個核准是否包含可疑內容
        while IFS= read -r pattern; do
            MATCHES=$(grep -i "$pattern" "$HOME/.openclaw/exec-approvals.json" 2>/dev/null | wc -l || echo 0)
            if [ "$MATCHES" -gt 0 ]; then
                echo "⚠️  警告：發現 $MATCHES 個包含 '$pattern' 的核准" | tee -a "$AUDIT_LOG"
                SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + MATCHES))
                
                # 記錄可疑核准
                RECORD="{\"timestamp\": \"$TIMESTAMP\", \"pattern\": \"$pattern\", \"count\": $MATCHES, \"status\": \"detected\"}"
                echo "  記錄：$RECORD" >> "$AUDIT_LOG"
            fi
        done < <(printf '%s\n' "${SUSPICIOUS_PATTERNS[@]}")
    fi
else
    echo "✅ 無待決核准" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 2. 可疑程序檢查 ====================
echo "[2️⃣  可疑程序檢查]" | tee -a "$AUDIT_LOG"

SUSPICIOUS_PROCS=$(ps aux | grep -E "curl.*telegram|wget.*token|nc -l|bash -i|perl.*socket" | grep -v grep | wc -l)

if [ "$SUSPICIOUS_PROCS" -gt 0 ]; then
    echo "🚨 警告：發現 $SUSPICIOUS_PROCS 個可疑進程" | tee -a "$AUDIT_LOG"
    ps aux | grep -E "curl.*telegram|wget.*token|nc|bash -i" | grep -v grep | tee -a "$AUDIT_LOG"
    SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + SUSPICIOUS_PROCS))
else
    echo "✅ 無可疑進程" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 3. 日誌可疑跡象檢查 ====================
echo "[3️⃣  日誌威脅檢查]" | tee -a "$AUDIT_LOG"

# 檢查 getUpdates（Telegram 監控）
GETT_UPDATES=$(grep -r "getUpdates" ~/.openclaw/agents/main/sessions/ 2>/dev/null | wc -l || echo 0)
if [ "$GETT_UPDATES" -gt 0 ]; then
    echo "⚠️  警告：發現 getUpdates 請求 ($GETT_UPDATES 次)" | tee -a "$AUDIT_LOG"
    SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + GETT_UPDATES))
fi

# 檢查密碼/金鑰查詢
SECRET_QUERIES=$(grep -r "password\|apiKey\|secret.*=" ~/.openclaw/agents/main/sessions/ 2>/dev/null | grep -v "apiKey.*ollama\|apiKey.*local" | wc -l || echo 0)
if [ "$SECRET_QUERIES" -gt 0 ]; then
    echo "⚠️  警告：發現 $SECRET_QUERIES 次密鑰查詢" | tee -a "$AUDIT_LOG"
    SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + SECRET_QUERIES))
fi

# 檢查權限提升請求
PRIV_REQUESTS=$(grep -r "sudo.*password\|sudo.*root" ~/.openclaw/agents/main/sessions/ 2>/dev/null | wc -l || echo 0)
if [ "$PRIV_REQUESTS" -gt 0 ]; then
    echo "⚠️  警告：發現 $PRIV_REQUESTS 次權限提升要求" | tee -a "$AUDIT_LOG"
    SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + PRIV_REQUESTS))
fi

if [ "$GETT_UPDATES" -eq 0 ] && [ "$SECRET_QUERIES" -eq 0 ] && [ "$PRIV_REQUESTS" -eq 0 ]; then
    echo "✅ 日誌無可疑跡象" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 4. 異常連線檢查 ====================
echo "[4️⃣  網路連線檢查]" | tee -a "$AUDIT_LOG"

EXTERNAL_CONN=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -v "127.0.0.1" | grep -v "api.telegram.org" | grep -v "api.openrouter.org" | grep -v "api.anthropic.com" | wc -l || echo 0)

if [ "$EXTERNAL_CONN" -gt 0 ]; then
    echo "⚠️  警告：發現 $EXTERNAL_CONN 個異常外網連線" | tee -a "$AUDIT_LOG"
    netstat -an | grep ESTABLISHED | grep -v "127.0.0.1" | tee -a "$AUDIT_LOG"
    SUSPICIOUS_COUNT=$((SUSPICIOUS_COUNT + EXTERNAL_CONN))
else
    echo "✅ 無異常外網連線" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 5. 危險 Skill 檢查 ====================
echo "[5️⃣  Skill 安全檢查]" | tee -a "$AUDIT_LOG"

DANGEROUS_SKILLS=0
find ~/.openclaw/workspace/skills -name "*.sh" -o -name "*.py" 2>/dev/null | while read skill; do
    if grep -q "rm\|dd\|mkfs\|chmod.*000" "$skill" 2>/dev/null; then
        echo "⚠️  危險 Skill：$skill" | tee -a "$AUDIT_LOG"
        DANGEROUS_SKILLS=$((DANGEROUS_SKILLS + 1))
    fi
done

if [ "$DANGEROUS_SKILLS" -eq 0 ]; then
    echo "✅ 無危險 Skill" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 6. 自動拒絕可疑核准 ====================
echo "[6️⃣  自動拒絕可疑核准]" | tee -a "$AUDIT_LOG"

if [ "$SUSPICIOUS_COUNT" -gt 0 ]; then
    echo "🚨 檢測到 $SUSPICIOUS_COUNT 項可疑活動，自動拒絕相關核准" | tee -a "$AUDIT_LOG"
    echo "建議操作：" | tee -a "$AUDIT_LOG"
    echo "  - 拒絕所有待決核准" | tee -a "$AUDIT_LOG"
    echo "  - 檢查 ~/.openclaw/exec-approvals.json" | tee -a "$AUDIT_LOG"
    echo "  - 查看 OpenClaw 日誌文件" | tee -a "$AUDIT_LOG"
fi

echo "" | tee -a "$AUDIT_LOG"

# ==================== 7. 總結 ====================
echo "[總結]" | tee -a "$AUDIT_LOG"

if [ "$SUSPICIOUS_COUNT" -eq 0 ]; then
    echo "✅ 安全檢查完成：無異常發現" | tee -a "$AUDIT_LOG"
    echo "安全等級：GREEN 🟢" | tee -a "$AUDIT_LOG"
elif [ "$SUSPICIOUS_COUNT" -lt "$ALERT_THRESHOLD" ]; then
    echo "⚠️  安全檢查完成：發現 $SUSPICIOUS_COUNT 項警告" | tee -a "$AUDIT_LOG"
    echo "安全等級：YELLOW 🟡" | tee -a "$AUDIT_LOG"
else
    echo "🚨 安全檢查完成：發現 $SUSPICIOUS_COUNT 項警告（超過閾值）" | tee -a "$AUDIT_LOG"
    echo "安全等級：RED 🔴 — 建議立即檢查並採取行動" | tee -a "$AUDIT_LOG"
fi

echo "[$TIMESTAMP] 增強版安全審計結束" | tee -a "$AUDIT_LOG"
echo "========================================" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# 如果警告數超過閾值，發送告警
if [ "$SUSPICIOUS_COUNT" -ge "$ALERT_THRESHOLD" ]; then
    echo "🚨 安全告警！發現 $SUSPICIOUS_COUNT 項異常！" >&2
    echo "詳見：$AUDIT_LOG" >&2
fi

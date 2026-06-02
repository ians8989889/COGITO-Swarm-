#!/bin/bash
# ============================================
# token_monitor.sh — 追蹤 token 使用量
# 用法: token_monitor.sh [daily|session]
# Token 花費: $0
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_LOG="${SKILL_DIR}/token_usage.log"
BOT_ID_FILE="${SKILL_DIR}/.bot-id"

BOT_NAME=$(grep '^bot_name:' "$BOT_ID_FILE" 2>/dev/null | awk '{print $2}' || echo "unknown")

mkdir -p "$(dirname "$TOKEN_LOG")"

MODE="${1:-daily}"

# ── 讀取 session status（透過 OpenClaw 內部機制） ──
# 此腳本由 OpenClaw agent 呼叫時會帶入 token 資訊
# 或透過環境變數傳入

get_latest_usage() {
  # 從最近的 session status 擷取（若有環境變數）
  if [[ -n "${OPENCLAW_TOKENS_IN:-}" ]]; then
    echo "${OPENCLAW_TOKENS_IN},${OPENCLAW_TOKENS_OUT},${OPENCLAW_COST:-0}"
    return
  fi
  
  # 否則從 log 讀取最後一筆
  if [[ -f "$TOKEN_LOG" ]]; then
    tail -1 "$TOKEN_LOG" | awk '{print $4}'
  else
    echo "N/A"
  fi
}

# ── 記錄 ──
TIMESTAMP=$(date -Iseconds)
USAGE=$(get_latest_usage)

echo "[${TIMESTAMP}] ${BOT_NAME} token=${USAGE}" >> "$TOKEN_LOG"

# ── 每日彙總 ──
if [[ "$MODE" == "daily" ]]; then
  TODAY=$(date +%Y-%m-%d)
  
  # 計算今日總 token（從 log 中篩選今天記錄）
  TODAY_COUNT=$(grep "$TODAY" "$TOKEN_LOG" 2>/dev/null | wc -l | tr -d ' ')
  
  echo "📊 ${BOT_NAME} Token 日報 (${TODAY})"
  echo "   今日記錄數: ${TODAY_COUNT}"
  echo "   最新: ${USAGE}"
  
  # 檢查警報閾值
  CONFIG_FILE="${SKILL_DIR}/config.yaml"
  if [[ -f "$CONFIG_FILE" ]]; then
    THRESHOLD=$(grep 'alert_threshold_daily:' "$CONFIG_FILE" | awk '{print $2}' 2>/dev/null || echo "5.00")
    # 簡化版：若日記錄數 > 100 則發警報（可改為實際金額計算）
    if [[ "$TODAY_COUNT" -gt 100 ]]; then
      echo "⚠️  今日請求數偏高 (${TODAY_COUNT})，建議檢查！"
    fi
  fi
fi

# ── Session 摘要 ──
if [[ "$MODE" == "session" ]]; then
  echo "📊 ${BOT_NAME} 當前 Session: ${USAGE}"
fi

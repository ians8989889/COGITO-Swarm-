#!/bin/bash
# RecoveryMBA-20260414 - Automated Recovery Script
# Usage: bash recover.sh

set -e

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RECOVERY_LOG="/Users/ericsu/.openclaw/workspace/recovery-$(date '+%Y%m%d-%H%M%S').log"

echo "========================================" | tee "$RECOVERY_LOG"
echo "🦐 RecoveryMBA-20260414 - Recovery Started" | tee -a "$RECOVERY_LOG"
echo "Time: $TIMESTAMP" | tee -a "$RECOVERY_LOG"
echo "========================================" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# ==================== Step 1: Check Ollama ====================
echo "[Step 1] Checking Ollama..." | tee -a "$RECOVERY_LOG"

if pgrep -f "ollama serve" >/dev/null; then
  echo "✅ Ollama is running (PID: $(pgrep -f 'ollama serve'))" | tee -a "$RECOVERY_LOG"
else
  echo "⚠️  Ollama not running, starting..." | tee -a "$RECOVERY_LOG"
  /Applications/Ollama.app/Contents/Resources/ollama serve &>/dev/null &
  sleep 5
  if pgrep -f "ollama serve" >/dev/null; then
    echo "✅ Ollama started successfully" | tee -a "$RECOVERY_LOG"
  else
    echo "❌ Failed to start Ollama" | tee -a "$RECOVERY_LOG"
    exit 1
  fi
fi

echo "✅ Ollama verification complete" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# ==================== Step 2: Restore Environment Variables ====================
echo "[Step 2] Restoring Ollama environment variables..." | tee -a "$RECOVERY_LOG"

launchctl setenv OLLAMA_API_KEY "ollama-local"
launchctl setenv OLLAMA_HOST "http://127.0.0.1:11434"
launchctl setenv OLLAMA_LLM_LIBRARY "metal"
launchctl setenv OLLAMA_NUM_GPU "999"
launchctl setenv OLLAMA_NUM_THREADS "8"
launchctl setenv OLLAMA_MAX_LOADED_MODELS "2"
launchctl setenv OLLAMA_KEEP_ALIVE "5m"
launchctl setenv OLLAMA_BATCH_SIZE "512"
launchctl setenv OLLAMA_CONTEXT_LENGTH "4096"
launchctl setenv OLLAMA_MEMORY_THRESHOLD "0.9"

echo "✅ Environment variables restored" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# ==================== Step 3: Restart Gateway ====================
echo "[Step 3] Restarting OpenClaw gateway..." | tee -a "$RECOVERY_LOG"

openclaw gateway restart | tee -a "$RECOVERY_LOG"
sleep 5

echo "✅ Gateway restart scheduled" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# ==================== Step 4: Verify System ====================
echo "[Step 4] Verifying system..." | tee -a "$RECOVERY_LOG"

echo "Gateway status:" | tee -a "$RECOVERY_LOG"
openclaw status 2>&1 | head -20 | tee -a "$RECOVERY_LOG"

echo "" | tee -a "$RECOVERY_LOG"
echo "Ollama models:" | tee -a "$RECOVERY_LOG"
ollama list | tee -a "$RECOVERY_LOG"

echo "" | tee -a "$RECOVERY_LOG"
echo "Available models for OpenClaw:" | tee -a "$RECOVERY_LOG"
openclaw models list --provider ollama 2>&1 | head -10 | tee -a "$RECOVERY_LOG"

echo "✅ System verification complete" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# ==================== Step 5: Check Cron Jobs ====================
echo "[Step 5] Checking cron jobs..." | tee -a "$RECOVERY_LOG"

SECURITY_JOB=$(openclaw cron list 2>&1 | grep -c "Security Audit" || echo 0)
HEARTBEAT_JOB=$(openclaw cron list 2>&1 | grep -c "Heartbeat" || echo 0)

if [ "$SECURITY_JOB" -gt 0 ]; then
  echo "✅ Security Audit job exists" | tee -a "$RECOVERY_LOG"
else
  echo "⚠️  Security Audit job missing (needs manual restore)" | tee -a "$RECOVERY_LOG"
fi

if [ "$HEARTBEAT_JOB" -gt 0 ]; then
  echo "✅ Heartbeat job exists" | tee -a "$RECOVERY_LOG"
else
  echo "⚠️  Heartbeat job missing (needs manual restore)" | tee -a "$RECOVERY_LOG"
fi

echo "" | tee -a "$RECOVERY_LOG"

# ==================== Summary ====================
echo "========================================" | tee -a "$RECOVERY_LOG"
echo "✅ Recovery Completed Successfully!" | tee -a "$RECOVERY_LOG"
echo "========================================" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"
echo "Recovery log saved to: $RECOVERY_LOG" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"
echo "Next steps:" | tee -a "$RECOVERY_LOG"
echo "1. Test the system by sending a message" | tee -a "$RECOVERY_LOG"
echo "2. Check 'openclaw status' for any issues" | tee -a "$RECOVERY_LOG"
echo "3. Review recovery log if any errors occurred" | tee -a "$RECOVERY_LOG"
echo "" | tee -a "$RECOVERY_LOG"

# 🦐 RecoveryMBA-20260414 Skill

**Name:** recoverymba-20260414  
**Description:** Complete system recovery skill - restore OpenClaw + Ollama after crash  
**Version:** 1.0.0  
**Created:** 2026-04-14  
**Last Updated:** 2026-04-15 13:36 GMT+8

---

## What it does

This skill performs a **complete system recovery** after OpenClaw or system crash. It restores:

1. ✅ Ollama environment variables
2. ✅ OpenClaw configuration
3. ✅ Telegram Bot token
4. ✅ Cron jobs (security audit + heartbeat)
5. ✅ System verification

---

## Quick Start

```bash
# View the recovery snapshot
cat ~/.openclaw/workspace/SYSTEM_STATE_SNAPSHOT.md

# Or run the automated recovery script
bash ~/.openclaw/workspace/skills/recoverymba-20260414/scripts/recover.sh
```

---

## System State on 2026-04-15

### Models
- **Primary:** ollama/qwen3:14b-opt (local, free)
- **Fallback:** ollama/gemma4:e4b (local, free)
- **Paid Backup:** anthropic/claude-haiku-4-5

### Ollama Environment Variables
```bash
OLLAMA_API_KEY="ollama-local"
OLLAMA_HOST="http://127.0.0.1:11434"
OLLAMA_LLM_LIBRARY=metal
OLLAMA_NUM_GPU=999
OLLAMA_NUM_THREADS=8
OLLAMA_MAX_LOADED_MODELS=2
OLLAMA_KEEP_ALIVE=5m
OLLAMA_BATCH_SIZE=512
OLLAMA_CONTEXT_LENGTH=4096
OLLAMA_MEMORY_THRESHOLD=0.9
```

### OpenClaw Configuration
- **Gateway Bind:** loopback (127.0.0.1:18789)
- **Telegram Token:** `8277120862:AAHJfb_GIMj-PG5nXw9KytfZxHeLTv94hZg`
- **Telegram Allowlist:** `8397380746` (only Eric Su)
- **Exec Approvals:** disabled (auto-execute)
- **Tailscale:** off

### Cron Jobs
| Name | Schedule | Purpose |
|------|----------|---------|
| Security Audit | 0 */8 * * * | Scan for threats every 8 hours |
| Heartbeat Check | Every 90 minutes | System status check |
| Telegram Polling | * * * * * | Receive messages every minute |

### Hardware
- CPU: Apple Silicon 8 cores
- Memory: 24 GB
- GPU: Metal 4
- Storage: ~18.9 GB (Ollama models)

---

## Recovery Steps

### Step 1: Verify Ollama is running
```bash
ps aux | grep ollama
ollama list
```

If not running:
```bash
/Applications/Ollama.app/Contents/Resources/ollama serve &
```

### Step 2: Restore Ollama environment variables
```bash
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
```

### Step 3: Restart OpenClaw Gateway
```bash
openclaw gateway restart
sleep 5
```

### Step 4: Verify system
```bash
openclaw status
openclaw models list --provider ollama
```

### Step 5: Restore Cron Jobs (if missing)
```bash
# Check existing jobs
openclaw cron list

# If Security Audit job missing, recreate:
# (Full command in scripts/restore-crons.sh)

# If Heartbeat job missing, recreate:
# (Full command in scripts/restore-crons.sh)
```

---

## Critical Files for Recovery

| File | Purpose |
|------|---------|
| `SYSTEM_STATE_SNAPSHOT.md` | Complete system configuration snapshot |
| `memory/2026-04-15.md` | Today's work log and decisions |
| `security-audit.sh` | Automated security audit script |
| `security-audit.log` | Security audit results |
| `OLLAMA_OPTIMIZATION_COMPLETE.md` | Original optimization report |
| `TELEGRAM_TOKEN_RESET.md` | Token reset guide |

---

## Troubleshooting

### Models showing as "missing"
```bash
# Verify Ollama is responding
curl http://localhost:11434/api/tags

# If not, restart Ollama
killall ollama
sleep 2
/Applications/Ollama.app/Contents/Resources/ollama serve &
```

### Telegram not working
```bash
# Check token is correct
grep "botToken" ~/.openclaw/openclaw.json

# If wrong, update to: 8277120862:AAHJfb_GIMj-PG5nXw9KytfZxHeLTv94hZg
# Then restart gateway
openclaw gateway restart
```

### Cron jobs not running
```bash
# Check job status
openclaw cron list

# Run a job immediately
openclaw cron run <job-id>

# View recent runs
openclaw cron runs <job-id>
```

### GPU not accelerating
```bash
# Check Metal is set
launchctl getenv OLLAMA_LLM_LIBRARY

# Should return: metal

# If not, reset and restart
launchctl setenv OLLAMA_LLM_LIBRARY "metal"
openclaw gateway restart
```

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Inference Speed | +40-60% (vs pre-optimization) |
| GPU Utilization | 80-90% |
| Response Latency | -20-30% |
| Cache Hit Rate | 100% |
| Memory Usage | <1% Ollama |
| Token Cost | $0 (local only) |

---

## Regular Maintenance

- **Weekly:** Check `security-audit.log` for threats
- **Monthly:** Verify all cron jobs are running
- **Quarterly:** Update `SYSTEM_STATE_SNAPSHOT.md`
- **On crash:** Follow 5-step recovery procedure above

---

## Support

**If recovery fails:**
1. Check `~/.ollama/ollama.log` for Ollama errors
2. Check `~/.openclaw/` for gateway errors
3. Run `openclaw doctor` for diagnostics
4. Verify network connectivity to localhost

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-04-15 | Initial recovery skill created |

---

**Created by:** 爆蝦 🦐  
**For:** Eric Su (蝦老大)  
**System:** macOS, Apple Silicon, 24GB RAM

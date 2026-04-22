#!/bin/bash
# Ollama Optimize Skill - Complete Setup Script
# Usage: bash setup.sh [--verify-only]

set -e

VERSION="1.0.0"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="$(cd "$SKILL_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Ollama Optimize Skill v${VERSION}${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse arguments
VERIFY_ONLY=false
if [[ "$1" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

# Function to check command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
  local status=$1
  local message=$2
  if [[ $status -eq 0 ]]; then
    echo -e "${GREEN}✅${NC} $message"
  else
    echo -e "${RED}❌${NC} $message"
  fi
}

# 1. Verify prerequisites
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"
command_exists ollama && print_status 0 "Ollama found" || print_status 1 "Ollama not found"
command_exists openclaw && print_status 0 "OpenClaw found" || print_status 1 "OpenClaw not found"

# 2. Check Ollama is running
echo ""
echo -e "${YELLOW}Step 2: Checking Ollama service...${NC}"
if pgrep -f "ollama serve" >/dev/null; then
  print_status 0 "Ollama service is running"
  ollama list | head -5
else
  print_status 1 "Ollama service is NOT running"
  echo "Start Ollama manually: /Applications/Ollama.app/Contents/Resources/ollama serve"
  exit 1
fi

# 3. Verify models exist
echo ""
echo -e "${YELLOW}Step 3: Verifying Ollama models...${NC}"
if ollama list | grep -q "qwen3:14b-opt"; then
  print_status 0 "qwen3:14b-opt model found"
else
  print_status 1 "qwen3:14b-opt model NOT found"
  echo "Pull the model: ollama pull qwen3:14b-opt"
fi

if [[ "$VERIFY_ONLY" == true ]]; then
  echo ""
  echo -e "${BLUE}Verification complete!${NC}"
  exit 0
fi

# 4. Set environment variables
echo ""
echo -e "${YELLOW}Step 4: Setting environment variables...${NC}"
launchctl setenv OLLAMA_API_KEY "ollama-local"
print_status 0 "OLLAMA_API_KEY set"

launchctl setenv OLLAMA_HOST "http://127.0.0.1:11434"
print_status 0 "OLLAMA_HOST set"

launchctl setenv OLLAMA_LLM_LIBRARY "metal"
print_status 0 "OLLAMA_LLM_LIBRARY set to metal"

launchctl setenv OLLAMA_NUM_GPU "999"
print_status 0 "OLLAMA_NUM_GPU set"

launchctl setenv OLLAMA_NUM_THREADS "8"
print_status 0 "OLLAMA_NUM_THREADS set to 8"

launchctl setenv OLLAMA_MAX_LOADED_MODELS "2"
print_status 0 "OLLAMA_MAX_LOADED_MODELS set"

launchctl setenv OLLAMA_KEEP_ALIVE "5m"
print_status 0 "OLLAMA_KEEP_ALIVE set"

launchctl setenv OLLAMA_BATCH_SIZE "512"
print_status 0 "OLLAMA_BATCH_SIZE set"

launchctl setenv OLLAMA_CONTEXT_LENGTH "4096"
print_status 0 "OLLAMA_CONTEXT_LENGTH set"

launchctl setenv OLLAMA_MEMORY_THRESHOLD "0.9"
print_status 0 "OLLAMA_MEMORY_THRESHOLD set"

# 5. Restart OpenClaw Gateway
echo ""
echo -e "${YELLOW}Step 5: Restarting OpenClaw gateway...${NC}"
openclaw gateway restart
print_status 0 "Gateway restart scheduled"

echo -e "${YELLOW}Waiting for gateway to start (5 seconds)...${NC}"
sleep 5

# 6. Verify configuration
echo ""
echo -e "${YELLOW}Step 6: Verifying Ollama integration...${NC}"
MODELS_OUTPUT=$(openclaw models list --provider ollama 2>&1 || true)
echo "$MODELS_OUTPUT"

if echo "$MODELS_OUTPUT" | grep -q "qwen3:14b-opt"; then
  print_status 0 "Ollama models detected by OpenClaw"
else
  print_status 1 "Ollama models NOT detected (may be loading...)"
fi

# 7. Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}📊 Current Configuration:${NC}"
echo "  Primary Model: ollama/qwen3:14b-opt"
echo "  Fallback: ollama/gemma4:e4b"
echo "  GPU: Metal 4 acceleration"
echo "  CPU: 8 threads"
echo "  Batch Size: 512"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "  1. Send a message to OpenClaw session"
echo "  2. Verify it's using Ollama model"
echo "  3. Monitor performance: ps aux | grep ollama"
echo ""
echo -e "${YELLOW}📝 For more info:${NC}"
echo "  - See: $SKILL_DIR/SKILL.md"
echo "  - Check logs: tail -50 ~/.ollama/ollama.log"
echo "  - List models: openclaw models list"
echo ""

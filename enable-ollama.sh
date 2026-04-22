#!/bin/bash
# 啟用 OpenClaw 與 Ollama auto-discovery 整合

echo "⏳ 啟用 Ollama auto-discovery..."

# 1. 設置 OLLAMA_API_KEY 環境變數
export OLLAMA_API_KEY="ollama-local"
launchctl setenv OLLAMA_API_KEY "ollama-local"

echo "✅ OLLAMA_API_KEY 已設置為 'ollama-local'"
echo "✅ OpenClaw 將自動發現本機 Ollama 模型"

# 2. 重啟 gateway
echo "🔄 重啟 OpenClaw gateway..."
openclaw gateway restart

sleep 5

echo ""
echo "✅ 完成！"
echo ""
echo "驗證方式："
echo "  openclaw models list"
echo ""
echo "預設模型已設為："
echo "  primary: ollama/gemma4:e4b"
echo "  fallbacks: ollama/qwen3:14b-opt, claude-haiku, claude-sonnet"

#!/bin/bash
# 設定 OpenClaw 使用 Ollama 作為預設模型

echo "⏳ 配置 Ollama 為 OpenClaw 主力模型..."

# 1. 設定環境變數
export OLLAMA_HOST="http://localhost:11434"
export OLLAMA_NUM_GPU=999

# 2. 重啟 gateway
echo "🔄 重啟 OpenClaw gateway..."
openclaw gateway restart

sleep 5

echo "✅ Ollama 配置完成！"
echo "預設模型：ollama/gemma4:e4b"
echo "備用模型：ollama/qwen3:14b-opt"

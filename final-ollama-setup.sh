#!/bin/bash
# 最終 Ollama 整合設置

echo "⏳ 設置 Ollama 環境變數..."
launchctl setenv OLLAMA_API_KEY "ollama-local"
launchctl setenv OLLAMA_HOST "http://127.0.0.1:11434"

echo "🔄 重啟 gateway..."
openclaw gateway restart

sleep 6

echo "✅ 完成！"
echo ""
echo "驗證模型狀態..."
openclaw models list --provider ollama

echo ""
echo "下一步："
echo "  1. 檢查上面模型是否還顯示 'missing'"
echo "  2. 如果變成 'ready'，就可以開始使用 Ollama 了！"
echo "  3. 發送一條訊息到 session 驗證模型"

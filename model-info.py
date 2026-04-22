#!/usr/bin/env python3
import asyncio
import edge_tts

TEXT = "目前的模型配置是：主力模型使用 OpenRouter Free，自動選擇免費模型池中的最佳模型。備用模型是 Anthropic Claude Sonnet，只在需要高能力任務時使用。Ollama 本地 14B 模型已配置，但尚未成功整合，待後續除錯。"
OUTPUT = "/Users/ericsu/.openclaw/workspace/model-info.mp3"
VOICE = "zh-CN-XiaoxiaoNeural"

async def main():
    communicate = edge_tts.Communicate(TEXT, VOICE)
    await communicate.save(OUTPUT)
    print(f"語音已生成：{OUTPUT}")

if __name__ == "__main__":
    asyncio.run(main())

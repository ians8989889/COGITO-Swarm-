#!/usr/bin/env python3
import asyncio
import edge_tts

TEXT = "現在的時間是二零二六年四月二日，十一点五十四分，星期四。"
OUTPUT = "/Users/ericsu/.openclaw/workspace/current-time.mp3"
VOICE = "zh-CN-XiaoxiaoNeural"

async def main():
    communicate = edge_tts.Communicate(TEXT, VOICE)
    await communicate.save(OUTPUT)
    print(f"語音已生成：{OUTPUT}")

if __name__ == "__main__":
    asyncio.run(main())

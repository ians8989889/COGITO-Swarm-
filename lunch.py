#!/usr/bin/env python3
import asyncio
import edge_tts

TEXT = "好，放飯去！去吃點好吃的。"
OUTPUT = "/Users/ericsu/.openclaw/workspace/lunch.mp3"
VOICE = "zh-CN-XiaoxiaoNeural"

async def main():
    communicate = edge_tts.Communicate(TEXT, VOICE)
    await communicate.save(OUTPUT)
    print(f"語音已生成：{OUTPUT}")

if __name__ == "__main__":
    asyncio.run(main())

#!/usr/bin/env python3
import asyncio
import edge_tts
import sys

TEXT = sys.argv[1] if len(sys.argv) > 1 else "這是語音回覆"
OUTPUT = sys.argv[2] if len(sys.argv) > 2 else "/Users/ericsu/.openclaw/workspace/output.mp3"
VOICE = "zh-CN-XiaoxiaoNeural"

async def main():
    communicate = edge_tts.Communicate(TEXT, VOICE)
    await communicate.save(OUTPUT)
    print(f"語音已生成：{OUTPUT}")

if __name__ == "__main__":
    asyncio.run(main())

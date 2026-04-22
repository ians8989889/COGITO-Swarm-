const { EdgeTTS } = require('/Users/ericsu/.npm-global/lib/node_modules/openclaw/node_modules/node-edge-tts/dist/edge-tts.js');

const text = process.argv[2] || '測試語音。我是爆蝦，你的 AI 助手。';
const outputFile = process.argv[3] || '/Users/ericsu/.openclaw/workspace/test-voice.mp3';

async function generateVoice() {
  try {
    const tts = new EdgeTTS();
    await tts.setVoice('zh-CN-XiaoxiaoNeural');
    await tts.setText(text);
    await tts.save(outputFile);
    console.log(`語音已生成：${outputFile}`);
  } catch (error) {
    console.error('生成語音失敗:', error.message);
    process.exit(1);
  }
}

generateVoice();

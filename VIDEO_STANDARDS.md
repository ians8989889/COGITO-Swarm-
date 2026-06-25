# 蝦宇宙影片製作規範 v1.0

> 所有蝦製作影片時必須遵守此規範。修改此文件需經蝦老大核准。
> 存放位置：SS Server http://192.168.1.103:18787/files/VIDEO_STANDARDS.md

---

## 📐 基礎規格

| 項目 | 規格 | 備註 |
|------|------|------|
| 解析度 | 768×1344 (9:16 直式) | YouTube Shorts 標準 |
| 幀率 | 24 fps | |
| 編碼 | H.264 (libx264) | 最大相容性 |
| CRF | 22 | 品質優先 |
| 音訊 | AAC 128kbps | |
| 片長 | 2-3 分鐘 | Shorts 最佳長度 |

---

## 🎨 字幕規範

| 項目 | 規格 |
|------|------|
| 字體 | STHeiti / PingFang（繁體中文） |
| 顏色 | 黃色 #FFD700 |
| 描邊 | 黑色陰影 2px offset |
| 字體大小 | 24-26px（768寬） / 80px（1080寬 4K） |
| 背景底條 | 黑色半透明 rgba(0,0,0,0.6) |
| 最大列數 | 3 列（含自動換行） |
| 位置 | 底部置中，距底邊 50-60px |
| 渲染方式 | **PIL 逐幀繪製**（不使用 ffmpeg overlay chain） |
| 腳本 | `build_subtitle.py` — 輸入影片 + JSON 時間軸 → 輸出字幕版 |

### 字幕 JSON 格式
```json
{
  "segments": [
    {
      "start": 0.0,
      "end": 38.6,
      "text": "第一段字幕文字\n第二行"
    }
  ]
}
```

---

## 🎤 語音規範

| 項目 | 規格 |
|------|------|
| TTS 引擎 | edge-tts (Microsoft Neural) |
| 語音 | zh-TW-HsiaoChenNeural（臺灣女聲） |
| 語速 | +0%（正常） |
| 格式 | MP3, 48kbps mono |

---

## 🖼️ 圖片生成規範

| 項目 | 規格 |
|------|------|
| 主要工具 | ComfyUI (192.168.1.120:8888) |
| 備用工具 | Google Gemini Image / LitMedia |
| 風格 | 教育科技風、暗藍底色、金色/青色點綴 |
| 數量 | 每段落 1 張（依內文分段） |
| 解析度 | 9:16 (768×1344 或 1080×1920) |

---

## 🎬 影片製作流程

```
1. 撰寫旁白稿 (narration.txt)
2. 依段落生成圖片（1 張/段）
3. TTS 語音生成 (narration.mp3)
4. 計算段落時間（依字數比例分配）
5. 合成影片（ffmpeg concat + audio）
6. 燒入字幕（PIL 逐幀 build_subtitle.py）
7. 上傳 YouTube（unlisted → 蝦老大審 → public）
```

---

## 📤 YouTube 上傳規範

| 項目 | 規格 |
|------|------|
| 頻道 | @3AIshrimps |
| 上傳方式 | `upload_eps.py` 腳本 |
| 初始狀態 | unlisted（不公開） |
| 公開條件 | 蝦老大審核通過後改為 public |

---

## 🔧 共用工具腳本

| 腳本 | 用途 |
|------|------|
| `build_subtitle.py` | PIL 逐幀字幕燒入（標準化） |
| `composite_eps.py` | 圖片串接 + 音訊合成 |
| `upload_eps.py` | YouTube 上傳 |

---

> 版本: v1.0 | 建立: 2026-06-25 | 蝦老大核准

# LitMedia Skill 安裝完成 ✅

**安裝時間：** 2026-04-17 16:57 GMT+8

## 📦 安裝詳情

### 位置
- **Skill 路徑：** `/Users/ericsu/.openclaw/workspace/skills/litmedia/`
- **Git 倉庫：** https://github.com/litmedia-ai/skill.git

### 已安裝的依賴
- ✅ `requests` (>=2.28.0)
- ✅ `python-dotenv` (>=1.0.0)
- ✅ `alibabacloud-oss-v2` (1.2.5)
- ✅ `pymediainfo` (7.0.1)

### 包含的模組

| 模組 | 腳本 | 功能 |
|------|------|------|
| Avatar4 | `scripts/avatar4.py` | 從照片生成會說話的頭像視頻 |
| Video Gen | `scripts/video_gen.py` | 圖片轉視頻、文字轉視頻、參考視頻生成 |
| AI Image | `scripts/ai_image.py` | 文字生成圖片、AI 圖片編輯 |
| Character Replace | `scripts/video_mimic.py` | 視頻中的角色替換 |
| User | `scripts/user.py` | 信用額度和使用歷史 |

## 🚀 下一步

### 1️⃣ **登錄 LitMedia 帳戶**
運行身份驗證：
```bash
python3 /Users/ericsu/.openclaw/workspace/skills/litmedia/scripts/auth.py login
```
這將生成一個登錄鏈接。在瀏覽器中打開並登錄。

### 2️⃣ **開始使用**
安裝完成後，你可以：
- 📹 生成視頻（文字轉視頻、圖片轉視頻）
- 🖼️ 生成圖片（支持 10+ AI 圖片模型）
- 🎭 創建頭像視頻（從照片）
- 🎙️ 文字轉語音
- 🎬 視頻風格轉換

## 📋 重要說明

### 使用規則
- **始終使用 Python 腳本**，不要使用 curl 或直接 HTTP 調用
- 認證後，環境變數會自動設置（`LITMEDIA_UID`、`LITMEDIA_API_KEY`）
- 所有操作都支持自然語言描述——只需告訴 AI 你想要什麼

### 估計生成時間
| 任務類型 | 預估時間 |
|---------|---------|
| 視頻生成 | 3-10 分鐘 |
| 圖片生成 | 30 秒 - 1 分鐘 |
| 頭像視頻 | 2-5 分鐘 |

## 🔐 安全提醒
- 保護你的 `LITMEDIA_API_KEY`
- 不要在公開代碼或日誌中暴露 API 金鑰
- 如需切換帳戶，使用 `auth.py accountswitch`

## 📚 文檔
完整使用指南見：`/Users/ericsu/.openclaw/workspace/skills/litmedia/SKILL.md`

---

**狀態：** ✅ 準備就緒，等待認證

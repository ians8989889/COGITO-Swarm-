# COGITO-Swarm Changelog

## v1.3.1 (2026-06-15) — 容錯與應變修補

### 🚨 新增：緊急應變機制
- 新增 `EMERGENCY_SOP.md`：故障分級（Lv0~3）、標準修復指令、CollabCore 容錯規則
- 新增 `TROUBLESHOOTING.md`：常見故障診斷與解法

### 🔧 架構更新
- ARCHITECTURE.md 新增「TG 通訊層依賴性」章節 — 文件化 TG 是系統的單點故障
- TG crash loop 症狀：`health-monitor: restarting (reason: stopped)` → 解法：`openclaw gateway restart`
- 新增 TG 健康檢查 cron 建議

### 🤝 CollabCore 容錯
- 主席掛 → 圓桌暫停
- 1 席缺 → 照開，備註缺席
- 2 席以上 → 降級雙人模式，不做正式決策

### 📋 文件更新
- README.md 新增 Troubleshooting 區
- SKILL.md 新增 #11 緊急應變技能
- 版本號一致性更新至 v1.3.1

---

## v1.3 (2026-06-11)
- UNCERTAINTY 協議：三級標記 [確信]/[推測]/[待查]
- 分層不確定性處理 + 人類分流

## v1.2
- 吸收 Gemini + ChatGPT 三方審查建議
- Compute/presentation 分離、Action-First、Decision Contract、Memory Governor

## v1.1
- 拆分 Ensemble 為 Bagging + Boosting
- ENSEMBLE_MODE 自動路由

## v1.0
- 初始版本：COGITO v4 × Shrimp-OS v6 整合

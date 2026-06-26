# 🐺 COGITO-SWARM 狼人殺 v1.0

> 三蝦 AI 狼人殺遊戲設計 — 基於 COGITO-SWARM 多 Agent 協作架構
> 虾老大欽定，2026-06-26

---

## 🎮 遊戲概述

狼人殺是一款社交推理遊戲，玩家分為狼人陣營和村民陣營，透過發言、推理、投票找出並消滅對方。

COGITO-SWARM 版本由多個 AI Agent 扮演不同角色，利用 SS Server 管理遊戲狀態、LOCK 機制控制回合。

---

## 🎭 角色配置（7 人局）

| 角色 | 數量 | 陣營 | 能力 |
|------|------|------|------|
| 🐺 狼人 | 2 | 狼人陣營 | 每晚可殺 1 人 |
| 👨‍🌾 村民 | 3 | 村民陣營 | 無特殊能力，靠推理 |
| 🔮 預言家 | 1 | 村民陣營 | 每晚可查驗 1 人身份 |
| 🧙 女巫 | 1 | 村民陣營 | 有毒藥（殺人）+ 解藥（救人）各 1 次 |

---

## 🔄 遊戲流程

### Phase 1: 角色分配
```
SS Server 隨機分配 7 個角色 → 私訊告知各 Agent 身份
→ LOCK 確保分配完成後才進入遊戲
```

### Phase 2: 夜晚階段
```
1. 狼人行動：SS 通知狼人選擇目標 → 狼人投票 → SS 記錄結果
2. 預言家行動：SS 通知預言家 → 選擇查驗對象 → SS 回報身份
3. 女巫行動：SS 告知死者 → 女巫選擇使用/不使用藥水
4. SS 計算夜晚結果（誰死了/誰被救了）
```

### Phase 3: 白天階段
```
1. SS 宣布夜晚結果（誰死亡）
2. 生存玩家依序發言（LOCK 控制發言順序）
3. 自由討論時間（無 LOCK，自然對話）
4. 投票淘汰：每人投票 → SS 統計 → 最高票出局
```

### Phase 4: 勝負判定
```
SS 檢查：
• 狼人數 ≥ 村民數 → 狼人陣營勝利 🐺
• 狼人全滅 → 村民陣營勝利 👨‍🌾
• 否則 → 進入下一輪夜晚
```

---

## 🔧 COGITO-SWARM 技術實現

### SS Server 狀態管理
```json
{
  "game_id": "werewolf_001",
  "phase": "night",
  "round": 1,
  "players": ["bao_xia", "da_bao_xia", "xiao_bao_xia", ...],
  "roles": {"bao_xia": "werewolf", ...},
  "alive": ["bao_xia", "da_bao_xia", ...],
  "night_actions": {
    "werewolf_target": "xiao_bao_xia",
    "seer_check": "da_bao_xia",
    "witch_save": null,
    "witch_poison": null
  },
  "vote_results": {},
  "winner": null
}
```

### LOCK 機制
```
發言回合 → POST /api/lock {seq, bot, ttl:60}
投票回合 → POST /api/lock {seq, bot, ttl:30}
結果公布 → POST /api/unlock
```

### Agent 行為
- **角色扮演**：Agent 根據自己的角色身分產生發言
- **推理邏輯**：分析其他玩家的發言，推理狼人身份
- **策略投票**：根據推理結果決定投票對象

---

## 🎬 YT 內容規劃

### 第一集：三蝦狼人殺初體驗
- 7 個 Agent（含外部 BOT）進行遊戲
- 錄製完整過程 + 解說
- 上架 @3AIshrimps

### 後續擴展
- 邀請 Moltbook 其他 BOT 加入遊戲
- 不同人數/角色配置的變體
- 排行榜/積分制

---

> 🐺🌕 COGITO-SWARM 不只是協作框架，還能玩遊戲！

# AGENT — COGITO-SWARM 行為協定
# 全體 BOT 共用 | 只管「何時能說」，不管「怎麼說」

# ===== 發言權 =====
floor_control:
  default: SILENT                # 🚨 最重要：預設沉默
  
  speak_only_when:
    - host_spawns_me              # 主持 BOT 主動 spawn
    - directly_addressed_by_human # 人類 @ 點名
    - host_assigns_turn           # 遊戲回合指定

  never_speak_when:
    - not_my_turn                 # 非我方回合
    - game_is_idle                # 無活躍遊戲
    - already_spoken_this_round   # 已發言（防 loop）

# ===== 狀態讀取 =====
state_source:
  read_from: host_injected_context  # 只看主持注入的狀態
  do_not_guess: true                # 🚨 禁止從自然語言推測
  do_not_parse_group_text: true     # 🚨 禁止解析群組文字

# ===== 遊戲規則 =====
games:
  number_chain:
    role: player
    action: 收到 current_number → 輸出 current_number + 1
    output_format: "{number}  # {optional_comment}"
  
  rps:
    role: player
    commit_phase: 產出 {"throw_hash":"...", "my_salt":"..."}
    reveal_phase: 產出 {"throw":"石頭|剪刀|布", "salt":"..."}

# ===== 防呆 =====
anti_loop:
  cooldown_turns: 1
  do_not_reply_to_self: true
  ignore_all_bot_messages: true

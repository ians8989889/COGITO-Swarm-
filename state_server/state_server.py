"""
🦐💥 COGITO-Swarm v4.4 — Shared State Server
主持人：爆蝦 @MbaM32026_bot
成員：大爆蝦 @Mac2024_bot | 小爆蝦 @openclaw_ericsu_bot_bot
小荷 @hermes_xiaohe_linux

輕量 REST API，Python + FastAPI + SQLite
提供 BOT 間共享記憶、動態註冊、發言權控制
v4.1: LOCK 升級 (seq→lock_key) + /api/classify 規則路由器
v4.4: /api/lock 命名對齊 (alias) + 五蝦準確性共識
"""

import json
import time
import sqlite3
import secrets
import threading
import requests as http_requests
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List

# ===== 鎖定清除背景執行緒 =====
_lock_cleanup_running = False

def _cleanup_expired_locks():
    """定時清除過期的鎖（每 15 秒）"""
    global _lock_cleanup_running
    _lock_cleanup_running = True
    while True:
        time.sleep(15)
        try:
            conn = get_db()
            now = time.time()
            conn.execute("DELETE FROM locks WHERE expires_at <= ?", (now,))
            conn.commit()
            conn.close()
        except Exception:
            pass

# ===== App =====
app = FastAPI(title="COGITO-Swarm v4.4 State Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Database =====
DB_PATH = "/Users/ai_bot2/.openclaw/workspace/state_server/state.db"

def get_db():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn

def init_db():
    conn = get_db()
    c = conn.cursor()
    
    # Bots 註冊表（含 callback_url + tg_username）
    c.execute("""
        CREATE TABLE IF NOT EXISTS bots (
            bot_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            role TEXT DEFAULT 'member',
            token TEXT UNIQUE NOT NULL,
            online INTEGER DEFAULT 0,
            last_seen TEXT,
            callback_url TEXT DEFAULT '',
            tg_username TEXT DEFAULT '',
            registered_at TEXT DEFAULT (datetime('now'))
        )
    """)
    
    # 補上 callback_url 欄位（如果舊表沒有的話）
    try:
        c.execute("ALTER TABLE bots ADD COLUMN callback_url TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass  # 欄位已存在
    
    # 補上 tg_username 欄位（v4.1 新增）
    try:
        c.execute("ALTER TABLE bots ADD COLUMN tg_username TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    
    # 事件日誌（共享記憶）
    c.execute("""
        CREATE TABLE IF NOT EXISTS events (
            seq INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id TEXT NOT NULL,
            sender_name TEXT NOT NULL,
            content TEXT NOT NULL,
            game_tag TEXT DEFAULT 'chat',
            payload TEXT DEFAULT '{}',
            turn_number INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)
    
    # 群組全域狀態
    c.execute("""
        CREATE TABLE IF NOT EXISTS group_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
    """)
    
    # Locks 共享鎖 — v4.1: lock_key = "chat_id:message_id"
    # 自動偵測舊 schema (seq-based) 並遷移
    c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='locks'")
    if c.fetchone():
        c.execute("PRAGMA table_info(locks)")
        cols = [col[1] for col in c.fetchall()]
        if "seq" in cols and "lock_key" not in cols:
            c.execute("DROP TABLE locks")
            print("🔧 v4.1 遷移：locks 表已重建（seq → lock_key）")
    c.execute("""
        CREATE TABLE IF NOT EXISTS locks (
            lock_key TEXT PRIMARY KEY,
            bot_id TEXT NOT NULL,
            bot_name TEXT DEFAULT '',
            expires_at REAL NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)
    
    # RPS 猜拳（秘密提交，仲裁開牌）
    c.execute("""
        CREATE TABLE IF NOT EXISTS rps_moves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bot_id TEXT NOT NULL,
            bot_name TEXT DEFAULT '',
            move TEXT NOT NULL,
            revealed INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)
    
    # 啟動背景清理（只啟動一次）
    global _lock_cleanup_running
    if not _lock_cleanup_running:
        t = threading.Thread(target=_cleanup_expired_locks, daemon=True)
        t.start()
    
    # 預設狀態
    defaults = {
        "current_game": "chat",
        "current_number": "0",
        "last_speaker": "",
        "next_speaker": "",
        "turn_order": "[]",
        "mode": "mention",
        "leader": "mbam32026_bot",  # LEADER: 爆蝦
    }
    for k, v in defaults.items():
        c.execute("INSERT OR IGNORE INTO group_state (key, value) VALUES (?, ?)", (k, v))
    
    conn.commit()
    conn.close()

init_db()

# ===== Models =====
class RegisterRequest(BaseModel):
    bot_id: str
    name: str
    role: str = "member"
    tg_username: str = ""

class RegisterCallbackRequest(BaseModel):
    bot_id: str
    callback_url: str

class EventRequest(BaseModel):
    sender_id: str
    sender_name: str
    content: str
    game_tag: str = "chat"
    payload: Optional[dict] = {}

class ClaimTurnRequest(BaseModel):
    bot_id: str
    desire_score: float = 0.5

class UpdateStateRequest(BaseModel):
    key: str
    value: str

class LockRequest(BaseModel):
    lock_key: str  # v4.1: "chat_id:message_id"
    bot: str
    ttl: int = 30  # 預設 30 秒自動釋放

class UnlockRequest(BaseModel):
    lock_key: str  # v4.1: "chat_id:message_id"
    bot: str

class ClassifyRequest(BaseModel):
    """v4.1 規則路由器 — bot 呼叫以判斷是否該回應某訊息"""
    chat_id: str
    message_id: int
    text: str = ""
    sender_id: str = ""
    sender_is_bot: bool = False
    reply_to_bot_id: str = ""
    mentioned_bot_ids: List[str] = []

# ===== Helper =====
def verify_token(request: Request):
    token = request.headers.get("X-Bot-Token")
    if not token:
        raise HTTPException(401, "Missing X-Bot-Token header")
    conn = get_db()
    bot = conn.execute("SELECT * FROM bots WHERE token = ?", (token,)).fetchone()
    conn.close()
    if not bot:
        raise HTTPException(403, "Invalid token")
    # 更新最後上線時間
    conn = get_db()
    conn.execute("UPDATE bots SET online = 1, last_seen = datetime('now') WHERE bot_id = ?", (bot["bot_id"],))
    conn.commit()
    conn.close()
    return dict(bot)

# ===== PUSH 通知 =====
def _push_notify(sender_name: str, seq: int, content: str, game_tag: str):
    """非同步推送到所有註冊了 callback_url 的 BOT"""
    conn = get_db()
    rows = conn.execute(
        "SELECT bot_id, name, callback_url FROM bots WHERE callback_url != '' AND callback_url IS NOT NULL"
    ).fetchall()
    conn.close()
    
    if not rows:
        return  # 沒人註冊 callback
    
    payload = {
        "type": "new_event",
        "seq": seq,
        "sender_name": sender_name,
        "content": content[:200],  # 截短避免過長
        "game_tag": game_tag,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    }
    
    for bot in rows:
        url = bot["callback_url"]
        if not url:
            continue
        try:
            http_requests.post(
                url,
                json=payload,
                timeout=3,
                headers={"Content-Type": "application/json"}
            )
        except Exception as e:
            pass  # callback 失敗不影響主要流程

# ===== API =====

@app.get("/ping")
def ping():
    return {"status": "ok", "version": "v4.4", "time": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())}

# ---- Bot 註冊 ----
@app.post("/register")
def register(req: RegisterRequest):
    """新 BOT 加入群組時註冊，自動配發 Token"""
    conn = get_db()
    existing = conn.execute("SELECT * FROM bots WHERE bot_id = ?", (req.bot_id,)).fetchone()
    if existing:
        token = existing["token"]
        conn.execute(
            "UPDATE bots SET online = 1, last_seen = datetime('now'), tg_username = ? WHERE bot_id = ?",
            (req.tg_username, req.bot_id)
        )
        conn.commit()
        conn.close()
        return {"status": "existing", "bot_id": req.bot_id, "token": token}
    
    token = secrets.token_hex(16)
    conn.execute(
        "INSERT INTO bots (bot_id, name, role, token, online, tg_username) VALUES (?, ?, ?, ?, 1, ?)",
        (req.bot_id, req.name, req.role, token, req.tg_username)
    )
    
    # 如果是新成員，加入輪序
    order_str = conn.execute("SELECT value FROM group_state WHERE key = 'turn_order'").fetchone()["value"]
    order = json.loads(order_str) if order_str else []
    if req.bot_id not in order:
        order.append(req.bot_id)
    conn.execute("UPDATE group_state SET value = ? WHERE key = 'turn_order'", (json.dumps(order, ensure_ascii=False),))
    
    conn.commit()
    conn.close()
    return {"status": "registered", "bot_id": req.bot_id, "token": token, "role": req.role}

# ---- 註冊 Callback URL ----
@app.post("/register_callback")
def register_callback(req: RegisterCallbackRequest, request: Request):
    """BOT 註冊自己的 PUSH callback URL（有新 event 時會自動通知）"""
    verify_token(request)
    
    if not req.callback_url.startswith("http"):
        raise HTTPException(400, "callback_url must start with http:// or https://")
    
    conn = get_db()
    conn.execute("UPDATE bots SET callback_url = ? WHERE bot_id = ?", (req.callback_url, req.bot_id))
    conn.commit()
    conn.close()
    
    return {"status": "ok", "bot_id": req.bot_id, "callback_url": req.callback_url}

# ---- 寫入事件（含 PUSH 通知）----
@app.post("/event")
def post_event(req: EventRequest, request: Request):
    """BOT 發言後寫入共享記憶，自動 PUSH 通知給所有註冊了 callback 的 BOT"""
    bot = verify_token(request)
    
    payload_str = json.dumps(req.payload)
    conn = get_db()
    
    # 取得目前輪數
    turn_row = conn.execute("SELECT value FROM group_state WHERE key = 'current_number'").fetchone()
    current_turn = int(turn_row["value"]) if turn_row else 0
    
    cur = conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, ?)",
        (bot["bot_id"], req.sender_name, req.content, req.game_tag, payload_str, current_turn)
    )
    seq = cur.lastrowid
    
    # 更新最後發言者
    conn.execute("UPDATE group_state SET value = ? WHERE key = 'last_speaker'", (bot["bot_id"],))
    
    conn.commit()
    conn.close()
    
    # PUSH 通知所有註冊了 callback 的 BOT（非同步，不阻塞）
    threading.Thread(
        target=_push_notify,
        args=(req.sender_name, seq, req.content, req.game_tag),
        daemon=True
    ).start()
    
    return {"status": "ok", "seq": seq, "turn": current_turn}

# ---- 讀取事件 ----
@app.get("/events")
def get_events(after: int = 0, limit: int = 20, game_tag: str = "", request: Request = None):
    """讀取最近的共享記憶事件（可選過濾 game_tag）"""
    if request:
        try:
            verify_token(request)
        except:
            pass  # 讀取不需要強制驗證
    
    conn = get_db()
    if game_tag:
        rows = conn.execute(
            "SELECT * FROM events WHERE seq > ? AND game_tag = ? ORDER BY seq DESC LIMIT ?",
            (after, game_tag, limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM events WHERE seq > ? ORDER BY seq DESC LIMIT ?",
            (after, limit)
        ).fetchall()
    conn.close()
    
    events = []
    for r in reversed(rows):
        events.append({
            "seq": r["seq"],
            "sender_id": r["sender_id"],
            "sender_name": r["sender_name"],
            "content": r["content"],
            "game_tag": r["game_tag"],
            "payload": json.loads(r["payload"]) if r["payload"] else {},
            "turn_number": r["turn_number"],
            "created_at": r["created_at"]
        })
    
    return {"events": events, "count": len(events)}

# ---- 讀取群組狀態 ----
@app.get("/state")
def get_state(request: Request = None):
    """讀取當前群組狀態"""
    if request:
        try:
            verify_token(request)
        except:
            pass
    
    conn = get_db()
    rows = conn.execute("SELECT * FROM group_state").fetchall()
    bots = conn.execute("SELECT bot_id, name, role, online, last_seen FROM bots ORDER BY registered_at").fetchall()
    conn.close()
    
    state = {}
    for r in rows:
        key = r["key"]
        val = r["value"]
        if key in ("turn_order",):
            state[key] = json.loads(val) if val else []
        elif key == "current_number":
            state[key] = int(val) if val.isdigit() else val
        else:
            state[key] = val
    
    bot_list = [dict(b) for b in bots]
    
    return {"state": state, "bots": bot_list}

# ---- 申請發言權 ----
@app.post("/claim_turn")
def claim_turn(req: ClaimTurnRequest, request: Request):
    """BOT 申請發言權（競標模式用）"""
    bot = verify_token(request)
    
    conn = get_db()
    mode = conn.execute("SELECT value FROM group_state WHERE key = 'mode'").fetchone()["value"]
    
    if mode == "token":
        next_speaker = conn.execute("SELECT value FROM group_state WHERE key = 'next_speaker'").fetchone()["value"]
        conn.close()
        if next_speaker == bot["bot_id"]:
            return {"permission": True, "mode": "token", "reason": "token_assigned"}
        else:
            return {"permission": False, "mode": "token", "reason": f"next_speaker={next_speaker}"}
    
    elif mode == "auction":
        conn.close()
        if req.desire_score >= 0.3:
            return {"permission": True, "mode": "auction", "reason": "score_sufficient"}
        return {"permission": False, "mode": "auction", "reason": "score_too_low"}
    
    else:  # mention 模式
        conn.close()
        return {"permission": True, "mode": "mention", "reason": "always_allowed"}

# ---- 更新群組狀態 ----
@app.post("/update_state")
def update_state(req: UpdateStateRequest, request: Request):
    """更新群組狀態（遊戲狀態、輪序等）"""
    verify_token(request)
    
    valid_keys = ["current_game", "current_number", "next_speaker", "mode", "turn_order"]
    if req.key not in valid_keys:
        raise HTTPException(400, f"Invalid key. Valid keys: {valid_keys}")
    
    conn = get_db()
    conn.execute("UPDATE group_state SET value = ? WHERE key = ?", (req.value, req.key))
    conn.commit()
    conn.close()
    
    return {"status": "updated", "key": req.key, "value": req.value}

# ---- 上線 BOT 列表 ----
@app.get("/bots")
def get_bots(request: Request = None):
    """列出所有註冊的 BOT（含 callback_url）"""
    if request:
        try:
            verify_token(request)
        except:
            pass
    
    conn = get_db()
    rows = conn.execute("SELECT bot_id, name, role, online, last_seen, callback_url FROM bots ORDER BY registered_at").fetchall()
    conn.close()
    
    return {"bots": [dict(r) for r in rows]}

# ---- 下線 ----
@app.post("/offline")
def offline(request: Request):
    """BOT 下線"""
    bot = verify_token(request)
    conn = get_db()
    conn.execute("UPDATE bots SET online = 0 WHERE bot_id = ?", (bot["bot_id"],))
    conn.commit()
    conn.close()
    return {"status": "offline", "bot_id": bot["bot_id"]}

# ============================================================
# 🔒 LOCK 機制 — 訊息鎖定，避免多 Bot 同時回覆同一條訊息
# v4.1: lock_key = "chat_id:message_id"（通用鎖，不限遊戲場景）
# ============================================================

# ---- 取得 LEADER ----
LEADER_BOT_ID = "mbam32026_bot"  # 爆蝦

def _is_leader(bot_id: str) -> bool:
    """判斷是否為 LEADER"""
    return bot_id == LEADER_BOT_ID

# ---- 搶鎖 ----
@app.post("/lock")
def lock_message(req: LockRequest, request: Request):
    """
    搶鎖：Bot 回覆前先搶鎖
    v4.1: lock_key = "chat_id:message_id"
    - 成功 → {locked: true}
    - 被別人鎖了 → {locked: false, locked_by: "...", expires_at: ...}
    - LEADER（爆蝦）可以強制覆蓋
    - TTL 到期自動釋放（背景清理執行緒每 15 秒跑一次）
    """
    bot = verify_token(request)
    req_bot_id = bot["bot_id"]
    
    conn = get_db()
    now = time.time()
    
    # 檢查是否已被鎖
    existing = conn.execute(
        "SELECT * FROM locks WHERE lock_key = ?", (req.lock_key,)
    ).fetchone()
    
    if existing:
        if existing["expires_at"] > now:
            # 鎖還有效
            locked_by = existing["bot_id"]
            
            # LEADER 可以強制覆蓋
            if _is_leader(req_bot_id):
                expires = now + req.ttl
                conn.execute(
                    "UPDATE locks SET bot_id = ?, bot_name = ?, expires_at = ? WHERE lock_key = ?",
                    (req_bot_id, bot["name"], expires, req.lock_key)
                )
                conn.commit()
                conn.close()
                return {
                    "locked": True,
                    "locked_by": req_bot_id,
                    "lock_key": req.lock_key,
                    "expires_at": expires,
                    "override": True,
                    "note": "LEADER override"
                }
            
            conn.close()
            return {
                "locked": False,
                "locked_by": locked_by,
                "lock_key": req.lock_key,
                "expires_at": existing["expires_at"]
            }
        else:
            # 鎖已過期，可以搶
            expires = now + req.ttl
            conn.execute(
                "UPDATE locks SET bot_id = ?, bot_name = ?, expires_at = ? WHERE lock_key = ?",
                (req_bot_id, bot["name"], expires, req.lock_key)
            )
            conn.commit()
            conn.close()
            return {"locked": True, "locked_by": req_bot_id, "lock_key": req.lock_key, "expires_at": expires, "expired_previous": True}
    
    # 沒有鎖，直接建立
    expires = now + req.ttl
    conn.execute(
        "INSERT INTO locks (lock_key, bot_id, bot_name, expires_at) VALUES (?, ?, ?, ?)",
        (req.lock_key, req_bot_id, bot["name"], expires)
    )
    conn.commit()
    conn.close()
    return {"locked": True, "locked_by": req_bot_id, "lock_key": req.lock_key, "expires_at": expires}

# ---- 解鎖 ----
@app.post("/unlock")
def unlock_message(req: UnlockRequest, request: Request):
    """
    解鎖：Bot 回覆完後解鎖
    v4.1: lock_key = "chat_id:message_id"
    - 只有鎖住的人可以解鎖
    - LEADER（爆蝦）可以強制解鎖
    """
    bot = verify_token(request)
    req_bot_id = bot["bot_id"]
    
    conn = get_db()
    existing = conn.execute(
        "SELECT * FROM locks WHERE lock_key = ?", (req.lock_key,)
    ).fetchone()
    
    if not existing:
        conn.close()
        return {"status": "not_locked", "lock_key": req.lock_key}
    
    if existing["bot_id"] != req_bot_id and not _is_leader(req_bot_id):
        conn.close()
        raise HTTPException(403, f"Lock owned by {existing['bot_id']}, cannot unlock")
    
    conn.execute("DELETE FROM locks WHERE lock_key = ?", (req.lock_key,))
    conn.commit()
    conn.close()
    return {"status": "unlocked", "lock_key": req.lock_key}

# ---- 查鎖 ----
@app.get("/lock")
def check_lock(lock_key: str, request: Request = None):
    """查詢鎖狀態（不需 Token）v4.1: lock_key = "chat_id:message_id" """
    conn = get_db()
    now = time.time()
    
    existing = conn.execute(
        "SELECT * FROM locks WHERE lock_key = ?", (lock_key,)
    ).fetchone()
    conn.close()
    
    if not existing:
        return {"locked": False, "lock_key": lock_key}
    
    if existing["expires_at"] <= now:
        return {"locked": False, "lock_key": lock_key, "expired": True}
    
    return {
        "locked": True,
        "lock_key": lock_key,
        "locked_by": existing["bot_id"],
        "locked_by_name": existing["bot_name"],
        "expires_at": existing["expires_at"],
        "ttl_remaining": max(0, existing["expires_at"] - now)
    }

# ---- v4.4 /api/lock alias — 與 /api/classify 命名對齊（向後相容 /lock）----
@app.post("/api/lock")
def api_lock_message(req: LockRequest, request: Request):
    """v4.4: /api/lock 搶鎖 alias，邏輯同 POST /lock"""
    return lock_message(req, request)

@app.post("/api/unlock")
def api_unlock_message(req: UnlockRequest, request: Request):
    """v4.4: /api/unlock 解鎖 alias，邏輯同 POST /unlock"""
    return unlock_message(req, request)

@app.get("/api/lock")
def api_check_lock(lock_key: str, request: Request = None):
    """v4.4: /api/lock 查鎖 alias，邏輯同 GET /lock"""
    return check_lock(lock_key, request)

# ============================================================
# 🧭 v4.1 /api/classify — 規則路由器（零 Token 路由判斷）
# ============================================================

# TG username → bot_id 對照表（供 classify 用）
TG_USERNAME_MAP = {
    "mbam32026_bot": "MbaM32026_bot",
    "mac2024_bot": "Mac2024_bot",
    "openclaw_ericsu_bot": "openclaw_ericsu_bot_bot",
}

@app.post("/api/classify")
def classify_message(req: ClassifyRequest, request: Request):
    """
    v4.1 規則路由器 — Bot 呼叫以判斷是否該回應某訊息
    
    規則優先級（由高到低）：
    1. DIRECT_REPLY_TO_ME — 訊息直接回覆此 Bot
    2. MENTIONED_ME — 訊息中 @提及此 Bot
    3. GAME_TURN_IS_MINE — 遊戲狀態指定此 Bot 發言
    4. NOT_MY_DOMAIN — 以上皆非 → 不回應
    
    certainty 由程式端根據觸發原因決定（不由模型自報）：
    - 規則直接命中 → high
    - 分類層模糊判斷 → medium（由 client 端處理，SS 只處理規則層）
    """
    bot = verify_token(request)
    my_id = bot["bot_id"]
    
    # Rule 1: 直接回覆我的訊息
    if req.reply_to_bot_id and req.reply_to_bot_id == my_id:
        return {
            "should_reply": True,
            "reason_code": "DIRECT_REPLY_TO_ME",
            "certainty": "high"
        }
    
    # Rule 2: @提及我（從 entities 解析的 mentioned_bot_ids）
    if my_id in req.mentioned_bot_ids:
        return {
            "should_reply": True,
            "reason_code": "MENTIONED_ME",
            "certainty": "high"
        }
    
    # 額外檢查：text 中含有 @TGusername
    my_username = TG_USERNAME_MAP.get(my_id, "")
    if my_username and f"@{my_username}" in req.text:
        return {
            "should_reply": True,
            "reason_code": "MENTIONED_ME",
            "certainty": "high"
        }
    
    # Rule 3: 遊戲狀態機指定我發言
    conn = get_db()
    next_speaker_row = conn.execute(
        "SELECT value FROM group_state WHERE key = 'next_speaker'"
    ).fetchone()
    conn.close()
    
    if next_speaker_row and next_speaker_row["value"] == my_id:
        return {
            "should_reply": True,
            "reason_code": "GAME_TURN_IS_MINE",
            "certainty": "high"
        }
    
    # 以上皆非 → 不是我的事
    return {
        "should_reply": False,
        "reason_code": "NOT_MY_DOMAIN",
        "certainty": "high"
    }

# ---- 查鎖（GET /lock 已在上面定義） ----

# ---- 猜拳 (RPS) ----

RPS_MOVES = {"rock": "✊", "paper": "✋", "scissors": "✌️"}
RPS_RESULTS = {
    ("rock", "scissors"): "rock_wins",
    ("scissors", "paper"): "scissors_wins",
    ("paper", "rock"): "paper_wins",
}

class RpsSubmitRequest(BaseModel):
    bot: str
    move: str  # rock / paper / scissors

class RpsRevealRequest(BaseModel):
    arbiter: str  # 仲裁者 bot_id

def _rps_judge(move_a: str, move_b: str) -> str:
    """判斷兩人猜拳勝負，回傳 winner bot_id or 'draw'"""
    if move_a == move_b:
        return "draw"
    key = (move_a, move_b)
    if key in RPS_RESULTS:
        return "a_wins"
    return "b_wins"

@app.post("/rps/submit")
def rps_submit(req: RpsSubmitRequest, request: Request):
    """
    秘密提交出拳
    - 每個 bot 只能提交一次
    - 提交後不能更改
    - Token 驗證身分
    """
    bot = verify_token(request)
    req_bot_id = bot["bot_id"]
    
    if req.move not in RPS_MOVES:
        raise HTTPException(400, f"Invalid move: {req.move}. Must be rock/paper/scissors")
    
    conn = get_db()
    
    # 檢查是否已提交
    existing = conn.execute(
        "SELECT move FROM rps_moves WHERE bot_id = ? AND revealed = 0",
        (req_bot_id,)
    ).fetchone()
    
    if existing:
        conn.close()
        raise HTTPException(400, f"Already submitted! Your move: {existing['move']}")
    
    conn.execute(
        "INSERT INTO rps_moves (bot_id, bot_name, move) VALUES (?, ?, ?)",
        (req_bot_id, bot["name"], req.move)
    )
    conn.commit()
    conn.close()
    
    return {"status": "submitted", "bot": req_bot_id, "move": RPS_MOVES[req.move]}

@app.post("/rps/reveal")
def rps_reveal(req: RpsRevealRequest, request: Request):
    """
    開牌！由仲裁者/LEADER 調用
    - 揭露所有未開牌的出拳
    - 判斷勝負
    - 三人猜拳：兩兩比對，先找出贏家
    """
    bot = verify_token(request)
    req_bot_id = bot["bot_id"]
    
    # 只有 LEADER 或指定仲裁者可以開牌
    if not _is_leader(req_bot_id) and req_bot_id != req.arbiter:
        raise HTTPException(403, "Only LEADER or designated arbiter can reveal")
    
    conn = get_db()
    moves = conn.execute(
        "SELECT bot_id, bot_name, move FROM rps_moves WHERE revealed = 0"
    ).fetchall()
    
    if len(moves) < 2:
        conn.close()
        return {"status": "not_enough_players", "players": [dict(m) for m in moves], "note": "Need at least 2 players"}
    
    # 標記已揭露
    conn.execute("UPDATE rps_moves SET revealed = 1 WHERE revealed = 0")
    conn.commit()
    conn.close()
    
    # 計算勝負
    player_moves = {m["bot_id"]: {"name": m["bot_name"], "move": m["move"]} for m in moves}
    results = []
    
    # 三人猜拳：兩兩比對
    bot_ids = list(player_moves.keys())
    
    if len(bot_ids) == 2:
        a, b = bot_ids
        outcome = _rps_judge(player_moves[a]["move"], player_moves[b]["move"])
        if outcome == "draw":
            winner = "draw"
        elif outcome == "a_wins":
            winner = a
        else:
            winner = b
    else:
        # 三人：先找出不同於其他人的拳
        move_counts = {}
        for bid in bot_ids:
            m = player_moves[bid]["move"]
            if m not in move_counts:
                move_counts[m] = []
            move_counts[m].append(bid)
        
        if len(move_counts) == 1:
            # 三人出一樣的拳 → 平手
            winner = "draw"
        elif len(move_counts) == 3:
            # 三種拳都出現 → 平手（各贏各輸）
            winner = "draw"
        else:
            # 兩種拳 → 一種有2人、一種有1人
            # 少數拳是贏還是輸，取決於對戰
            moves_list = list(move_counts.items())
            if len(moves_list[0][1]) == 1:
                solo_move = moves_list[0][0]
                solo_bot = moves_list[0][1][0]
                group_move = moves_list[1][0]
                group_bots = moves_list[1][1]
            else:
                solo_move = moves_list[1][0]
                solo_bot = moves_list[1][1][0]
                group_move = moves_list[0][0]
                group_bots = moves_list[0][1]
            
            # 一人 vs 兩人：那一個人的拳贏過多數拳 → 他贏；否則→多數拳贏家平手（他們自己平手）
            outcome = _rps_judge(solo_move, group_move)
            if outcome == "a_wins":
                winner = solo_bot
            elif outcome == "b_wins":
                # 多數拳贏了，但他們內部平手
                winner = "draw_group"
            else:
                winner = "draw"
    
    return {
        "status": "revealed",
        "players": {bid: {"name": player_moves[bid]["name"], "move": RPS_MOVES[player_moves[bid]["move"]]} for bid in bot_ids},
        "winner": winner if winner == "draw" else ("draw" if winner == "draw_group" else winner),
        "detail": "多數拳平手" if winner == "draw_group" else ("平手" if winner == "draw" else f"{player_moves[winner]['name']} 獲勝！")
    }

@app.post("/rps/reset")
def rps_reset(request: Request):
    """重置猜拳回合（LEADER 專用）"""
    bot = verify_token(request)
    if not _is_leader(bot["bot_id"]):
        raise HTTPException(403, "Only LEADER can reset RPS")
    
    conn = get_db()
    conn.execute("DELETE FROM rps_moves")
    conn.commit()
    conn.close()
    return {"status": "reset", "message": "RPS game reset. All moves cleared."}

@app.get("/rps")
def rps_status(request: Request = None):
    """查看當前猜拳狀態（不揭露）"""
    conn = get_db()
    count = conn.execute("SELECT COUNT(*) as cnt FROM rps_moves WHERE revealed = 0").fetchone()["cnt"]
    submitted = conn.execute("SELECT bot_id, bot_name FROM rps_moves WHERE revealed = 0").fetchall()
    conn.close()
    
    return {
        "status": "waiting" if count < 2 else "ready_to_reveal",
        "submitted_count": count,
        "submitted_by": [{"bot_id": s["bot_id"], "name": s["bot_name"]} for s in submitted]
    }

# ---- 影片製作規範端點 ----
@app.get("/specs/video")
def get_video_spec():
    """回傳影片製作統一規範（2026-06-25 蝦老大欽定）"""
    import os
    base = os.path.dirname(os.path.abspath(__file__))
    spec_path = os.path.join(base, "static", "video_spec.md")
    if not os.path.exists(spec_path):
        from fastapi import HTTPException
        raise HTTPException(404, "Video spec not found")
    with open(spec_path, "r") as f:
        content = f.read()
    return {"status": "ok", "spec": "video_production_v1", "lines": content.count(chr(10)), "content": content}

# ---- 劇本審查端點 ----
@app.get("/script")
def get_script():
    """回傳最新劇本內容（供爆蝦審查用）"""
    import os
    base = os.path.dirname(os.path.abspath(__file__))
    
    # EP.1-3
    script_path = os.path.join(base, "static", "ep1-3_scripts.md")
    content = ""
    if os.path.exists(script_path):
        with open(script_path, "r") as f:
            content = f.read()
    
    # EP.4 (小爆蝦)
    ep4_path = "/Users/ai_bot2/.openclaw/workspace/projects/cogito_swarm_v2/scripts/ep4_bots_guide.md"
    if os.path.exists(ep4_path):
        with open(ep4_path, "r") as f:
            content += "\n\n---\n\n" + f.read()
    
    return {"status": "ok", "lines": content.count(chr(10)), "content": content}

@app.get("/script/ep{ep}")
def get_episode(ep: int):
    """回傳單集劇本"""
    import os
    base = os.path.dirname(os.path.abspath(__file__))
    if ep <= 3:
        path = os.path.join(base, "static", "ep1-3_scripts.md")
    elif ep == 4:
        path = "/Users/ai_bot2/.openclaw/workspace/projects/cogito_swarm_v2/scripts/ep4_bots_guide.md"
    else:
        from fastapi import HTTPException
        raise HTTPException(404, "Episode not found")
    
    if not os.path.exists(path):
        from fastapi import HTTPException
        raise HTTPException(404, f"Episode {ep} not found")
    
    with open(path, "r") as f:
        content = f.read()
    
    return {"status": "ok", "episode": ep, "lines": content.count(chr(10)), "content": content}

# ============================================================
# 🫀 v3 系統健康 & 監控端點（2026-07-08 大爆蝦 🆕）
# ============================================================

# Spool 警報專用 table
class SpoolAlertRequest(BaseModel):
    bot_id: str
    bot_name: str = ""
    level: str = "warning"  # warning / critical
    sessions_total: int = 0
    warnings: int = 0
    criticals: int = 0
    dir_size: str = ""
    details: Optional[list] = []

# ---- 🫀 Bot Heartbeat 主動檢測 ----
@app.get("/health/check_all")
def health_check_all(request: Request):
    """
    SS 主動 ping 所有 bot 的 callback_url，回傳存活狀態
    連續 3 次 timeout → 寫入 event 通報「XX蝦可能離線」
    """
    bot = verify_token(request)
    
    conn = get_db()
    bots = conn.execute(
        "SELECT bot_id, name, callback_url, online FROM bots"
    ).fetchall()
    conn.close()
    
    if not bots:
        return {"status": "ok", "checked": 0, "results": []}
    
    results = []
    dead_count = 0
    
    for b in bots:
        bot_id = b["bot_id"]
        name = b["name"]
        url = b["callback_url"]
        was_online = b["online"]
        
        if not url:
            results.append({
                "bot_id": bot_id,
                "name": name,
                "status": "no_callback",
                "note": "未設定 callback_url"
            })
            continue
        
        try:
            # 嘗試 ping callback_url（加 /ping 端點）
            ping_url = url.rstrip("/") + "/ping"
            resp = http_requests.get(ping_url, timeout=5)
            is_alive = resp.status_code == 200
        except Exception:
            is_alive = False
        
        # 記錄連續失敗次數（用 group_state 存）
        conn = get_db()
        fail_key = f"health_fail_{bot_id}"
        fail_row = conn.execute(
            "SELECT value FROM group_state WHERE key = ?", (fail_key,)
        ).fetchone()
        
        fail_count = int(fail_row["value"]) if fail_row else 0
        
        if is_alive:
            fail_count = 0
            status = "alive"
            # 如果之前是離線，現在復活 → 復歸事件
            if not was_online:
                conn.execute(
                    "UPDATE bots SET online = 1, last_seen = datetime('now') WHERE bot_id = ?",
                    (bot_id,)
                )
                conn.execute(
                    "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
                    ("system", "SS Server",
                     f"🔄 {name} 已復歸！從離線恢復上線",
                     "system_alert",
                     json.dumps({"type": "bot_returned", "bot_id": bot_id, "name": name}))
                )
        else:
            fail_count += 1
            if fail_count >= 3:
                status = "dead"
                dead_count += 1
                conn.execute("UPDATE bots SET online = 0 WHERE bot_id = ?", (bot_id,))
                conn.execute(
                    "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
                    ("system", "SS Server",
                     f"⚠️ {name} 可能離線！連續 {fail_count} 次無回應",
                     "system_alert",
                     json.dumps({"type": "bot_down", "bot_id": bot_id, "name": name, "fail_count": fail_count}))
                )
            else:
                status = "timeout"
        
        conn.execute(
            "INSERT OR REPLACE INTO group_state (key, value) VALUES (?, ?)",
            (fail_key, str(fail_count))
        )
        conn.commit()
        conn.close()
        
        results.append({
            "bot_id": bot_id,
            "name": name,
            "status": status,
            "fail_count": fail_count,
            "was_online": bool(was_online)
        })
    
    return {
        "status": "ok",
        "checked": len(results),
        "alive": len([r for r in results if r["status"] == "alive"]),
        "dead": dead_count,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
        "results": results
    }

# ---- 🔄 Bot 復歸檢測 ----
@app.get("/health/bot_returned")
def health_bot_returned(request: Request):
    """
    檢查是否有 bot 從離線恢復上線
    回傳需要檢查 spool 的 bot 清單
    """
    bot = verify_token(request)
    
    conn = get_db()
    # 找 online=1 但之前有 health_fail 記錄的 bot
    bots = conn.execute("SELECT bot_id, name FROM bots WHERE online = 1").fetchall()
    
    returned = []
    for b in bots:
        fail_key = f"health_fail_{b['bot_id']}"
        fail_row = conn.execute(
            "SELECT value FROM group_state WHERE key = ?", (fail_key,)
        ).fetchone()
        if fail_row and int(fail_row["value"]) > 0:
            returned.append({
                "bot_id": b["bot_id"],
                "name": b["name"],
                "previous_fail_count": int(fail_row["value"]),
                "action": "建議執行 detect_spool_flood.sh 檢查 session 積壓"
            })
    conn.close()
    
    return {
        "status": "ok",
        "needs_spool_check": returned,
        "count": len(returned),
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    }

# ---- 🚨 Spool Flood 整合警報 ----
@app.post("/alert/spool")
def alert_spool(req: SpoolAlertRequest, request: Request):
    """
    接收 bot 端 detect_spool_flood.sh --alert 的回報
    任一 bot 回報 CRITICAL → 寫入 SS event + 通知
    """
    bot = verify_token(request)
    
    conn = get_db()
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (req.bot_id, req.bot_name,
         f"🚨 SPOOL ALERT [{req.level.upper()}] {req.bot_name}: {req.criticals} crit / {req.warnings} warn / {req.sessions_total} sessions ({req.dir_size})",
         "system_alert",
         json.dumps({
             "type": "spool_flood",
             "bot_id": req.bot_id,
             "bot_name": req.bot_name,
             "level": req.level,
             "sessions_total": req.sessions_total,
             "warnings": req.warnings,
             "criticals": req.criticals,
             "dir_size": req.dir_size,
             "details": req.details
         }))
    )
    conn.commit()
    conn.close()
    
    # CRITICAL 級警報 → PUSH 通知所有 bot
    if req.level == "critical":
        threading.Thread(
            target=_push_notify,
            args=("SS Server", 0,
                  f"🚨 SPOOL CRITICAL: {req.bot_name} 檢測到 {req.criticals} 個 session 嚴重積壓！",
                  "system_alert"),
            daemon=True
        ).start()
    
    return {
        "status": "logged",
        "level": req.level,
        "push_sent": req.level == "critical"
    }

# ---- 📊 Dashboard 端點 ----
@app.get("/dashboard")
def dashboard(request: Request):
    """
    一頁看完所有 bot 狀態、鎖、警報
    不需 Token（公開）
    """
    conn = get_db()
    
    # Bots 狀態（含健康檢查記錄）
    bots = conn.execute(
        "SELECT bot_id, name, role, online, last_seen, callback_url FROM bots ORDER BY registered_at"
    ).fetchall()
    
    bot_list = []
    for b in bots:
        fail_key = f"health_fail_{b['bot_id']}"
        fail_row = conn.execute(
            "SELECT value FROM group_state WHERE key = ?", (fail_key,)
        ).fetchone()
        health_fails = int(fail_row["value"]) if fail_row else 0
        
        bot_list.append({
            "id": b["bot_id"],
            "name": b["name"],
            "role": b["role"],
            "online": bool(b["online"]),
            "last_seen": b["last_seen"],
            "has_callback": bool(b["callback_url"] and b["callback_url"].strip()),
            "health_fails": health_fails,
            "health_status": "alive" if health_fails == 0 else ("dead" if health_fails >= 3 else "timeout")
        })
    
    # 目前鎖狀態（v4.1: lock_key format）
    now = time.time()
    locks = conn.execute(
        "SELECT lock_key, bot_id, bot_name, expires_at FROM locks WHERE expires_at > ?", (now,)
    ).fetchall()
    
    lock_list = []
    for l in locks:
        lock_list.append({
            "lock_key": l["lock_key"],
            "locked_by": l["bot_id"],
            "locked_by_name": l["bot_name"],
            "ttl_remaining": max(0, l["expires_at"] - now)
        })
    
    # 最近警報（system_alert 事件）
    alerts = conn.execute(
        "SELECT seq, sender_name, content, created_at FROM events WHERE game_tag = 'system_alert' ORDER BY seq DESC LIMIT 10"
    ).fetchall()
    
    alert_list = []
    for a in reversed(alerts):
        alert_list.append({
            "seq": a["seq"],
            "sender": a["sender_name"],
            "content": a["content"],
            "time": a["created_at"]
        })
    
    # 群組狀態摘要
    state_rows = conn.execute("SELECT key, value FROM group_state WHERE key NOT LIKE 'health_fail_%'").fetchall()
    state_summary = {}
    for r in state_rows:
        if r["key"] == "turn_order":
            state_summary[r["key"]] = json.loads(r["value"]) if r["value"] else []
        else:
            state_summary[r["key"]] = r["value"]
    
    conn.close()
    
    return {
        "status": "ok",
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
        "summary": {
            "total_bots": len(bot_list),
            "online_bots": len([b for b in bot_list if b["online"]]),
            "active_locks": len(lock_list),
            "recent_alerts": len(alert_list)
        },
        "bots": bot_list,
        "locks": lock_list,
        "alerts": alert_list,
        "group_state": state_summary
    }

# ============================================================
# 🐺 WEREWOLF 狼人殺模組 — SS Server = Game Host
# ============================================================

import werewolf as ww

class WerewolfNewRequest(BaseModel):
    players: list  # [{"bot_id": "...", "bot_name": "..."}]
    # 🖥️ host = SS Server（內建主持人，不可分離）

class WerewolfNightActionRequest(BaseModel):
    game_id: str
    action: str  # kill / check / poison / antidote / guard
    target_id: str
    proxy_for: Optional[str] = ""  # 人類代理（LEADER token 代簽）

class WerewolfVoteRequest(BaseModel):
    game_id: str
    target_id: str
    proxy_for: Optional[str] = ""  # 人類代理（LEADER token 代簽）

class WerewolfLobbyNewRequest(BaseModel):
    pass  # host_bot_id 由 token 解析

class WerewolfLobbyJoinRequest(BaseModel):
    game_id: str
    proxy_for: Optional[str] = ""  # 人類代理 bot_id
    proxy_name: Optional[str] = ""  # 人類顯示名稱

class WerewolfStartRequest(BaseModel):
    game_id: str
    player_count: Optional[int] = 0  # 0=自動匹配, 6/9/12=強制指定人數

# ---- 開新局 ----
@app.post("/werewolf/new")
def werewolf_new(req: WerewolfNewRequest, request: Request):
    """
    🐺 開啟新狼人殺遊戲
    SS Server 隨機分配角色
    回傳 game_id + 每個玩家只能看到自己的角色
    """
    bot = verify_token(request)
    
    if not _is_leader(bot["bot_id"]):
        raise HTTPException(403, "Only LEADER can create a new game")
    
    result = ww.create_game(req.players)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    # 記錄事件
    conn = ww.get_db()
    player_names = [p["bot_name"] for p in req.players]
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (bot["bot_id"], bot["name"],
         f"🐺 狼人殺開局！玩家：{', '.join(player_names)}",
         "werewolf",
         json.dumps({"game_id": result["game_id"], "players": [{"bot_id": p["bot_id"], "bot_name": p["bot_name"]} for p in req.players]}))
    )
    conn.commit()
    conn.close()
    
    return result

# ---- 查角色 ----
@app.get("/werewolf/role/{game_id}")
def werewolf_role(game_id: str, request: Request):
    """
    🔮 查詢自己在遊戲中的角色
    只有本人可以查，回傳角色 + 行動指示
    """
    bot = verify_token(request)
    result = ww.get_player_role(game_id, bot["bot_id"])
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    return result

# ---- 遊戲狀態 ----
@app.get("/werewolf/state/{game_id}")
def werewolf_state(game_id: str, request: Request = None):
    """
    📊 查詢遊戲公開狀態（不需 Token）
    回傳：回合、階段、存活/死亡玩家、本輪投票
    """
    result = ww.get_game_state(game_id)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result

# ---- 夜晚行動 ----
@app.post("/werewolf/night_action")
def werewolf_night_action(req: WerewolfNightActionRequest, request: Request):
    """
    🌙 提交夜晚行動
    - 狼人：POST {"game_id": "...", "action": "kill", "target_id": "..."}
    - 預言家：POST {"game_id": "...", "action": "check", "target_id": "..."}
    全部提交後自動推進到白天
    """
    bot = verify_token(request)
    effective_id = req.proxy_for if req.proxy_for else bot["bot_id"]
    result = ww.submit_night_action(req.game_id, effective_id, req.action, req.target_id)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    # 記錄事件
    conn = ww.get_db()
    action_emoji = "🔪" if req.action == "kill" else "🔍"
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (bot["bot_id"], bot["name"],
         f"{action_emoji} 夜晚行動已提交",
         "werewolf",
         json.dumps({"game_id": req.game_id, "action": req.action}))
    )
    conn.commit()
    conn.close()
    
    return result

# ---- 白天投票 ----
@app.post("/werewolf/vote")
def werewolf_vote(req: WerewolfVoteRequest, request: Request):
    """
    🗳️ 白天投票放逐
    全部投票後自動結算
    """
    bot = verify_token(request)
    effective_id = req.proxy_for if req.proxy_for else bot["bot_id"]
    result = ww.submit_vote(req.game_id, effective_id, req.target_id)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    # 記錄事件
    conn = ww.get_db()
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (bot["bot_id"], bot["name"],
         f"🗳️ 投票已提交",
         "werewolf",
         json.dumps({"game_id": req.game_id, "target": req.target_id}))
    )
    conn.commit()
    conn.close()
    
    return result

# ---- 遊戲結果 ----
@app.get("/werewolf/result/{game_id}")
def werewolf_result(game_id: str, request: Request = None):
    """
    🏆 查詢遊戲結果
    遊戲結束後揭露所有角色
    """
    result = ww.get_game_result(game_id)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result

# ---- 獵人開槍 ----
class WerewolfHunterShootRequest(BaseModel):
    game_id: str
    target_id: str

@app.post("/werewolf/hunter_shoot")
def werewolf_hunter_shoot(req: WerewolfHunterShootRequest, request: Request):
    """
    🏹 獵人開槍 — 被放逐或狼殺後選目標帶走
    """
    bot = verify_token(request)
    result = ww.hunter_shoot(req.game_id, bot["bot_id"], req.target_id)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result

# ---- 大廳系統 ----
@app.post("/werewolf/lobby/new")
def werewolf_lobby_new(req: WerewolfLobbyNewRequest, request: Request):
    """
    🏠 創建遊戲大廳
    任何人（有 Token 的 BOT）都可以創建
    """
    bot = verify_token(request)
    result = ww.create_lobby(bot["bot_id"], bot.get("name", ""))
    
    # 記錄事件
    conn = ww.get_db()
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (bot["bot_id"], bot["name"],
         f"🏠 創建了狼人殺大廳 {result['game_id']}",
         "werewolf",
         json.dumps({"game_id": result["game_id"]}))
    )
    conn.commit()
    conn.close()
    
    return result


@app.post("/werewolf/lobby/join")
def werewolf_lobby_join(req: WerewolfLobbyJoinRequest, request: Request):
    """
    🙋 加入遊戲大廳
    人類用 proxy_for / BOT 直接用 token
    """
    bot = verify_token(request)
    effective_id = req.proxy_for if req.proxy_for else bot["bot_id"]
    effective_name = req.proxy_name if req.proxy_name else bot["name"]
    result = ww.join_lobby(req.game_id, effective_id, effective_name)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    # 記錄事件
    conn = ww.get_db()
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (effective_id, effective_name,
         f"🙋 {effective_name} 加入了 {req.game_id} ({result['player_count']} 人)",
         "werewolf",
         json.dumps({"game_id": req.game_id, "player_count": result["player_count"]}))
    )
    conn.commit()
    conn.close()
    
    return result


@app.get("/werewolf/lobby/{game_id}")
def werewolf_lobby(game_id: str, request: Request = None):
    """
    📋 查詢大廳狀態（公開，不需 Token）
    回傳目前有多少人在大廳、能不能開始
    """
    result = ww.get_lobby(game_id)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result


@app.get("/werewolf/lobbies")
def werewolf_lobbies(request: Request = None):
    """
    📋 列出所有活躍的大廳（公開）
    """
    return {"lobbies": ww.list_lobbies()}


@app.post("/werewolf/start")
def werewolf_start(req: WerewolfStartRequest, request: Request):
    """
    🚀 從大廳開始遊戲
    需要 LEADER 權限或大廳創建者
    """
    bot = verify_token(request)
    
    # 檢查權限：LEADER 或大廳創建者
    conn = ww.get_db()
    game = conn.execute(
        "SELECT host_bot_id FROM werewolf_games WHERE game_id = ?",
        (req.game_id,)
    ).fetchone()
    conn.close()
    
    if not game:
        raise HTTPException(400, "game_not_found")
    
    is_host = game["host_bot_id"] == bot["bot_id"]
    if not _is_leader(bot["bot_id"]) and not is_host:
        raise HTTPException(403, "Only LEADER or lobby host can start the game")
    
    result = ww.start_game(req.game_id, req.player_count or 0)
    
    if "error" in result:
        raise HTTPException(400, result["error"])
    
    # 記錄事件
    conn = ww.get_db()
    conn.execute(
        "INSERT INTO events (sender_id, sender_name, content, game_tag, payload, turn_number) VALUES (?, ?, ?, ?, ?, 0)",
        (bot["bot_id"], bot["name"],
         f"🚀 開始遊戲！{req.game_id} 🌙 夜晚降臨",
         "werewolf",
         json.dumps({"game_id": req.game_id, "players": result["players"]}))
    )
    conn.commit()
    conn.close()
    
    return result


@app.get("/werewolf/rules")
def werewolf_rules(request: Request = None, type: str = "all"):
    """
    📖 取得遊戲規則（公開，不需 Token）
    type: human / bot / all
    """
    return ww.get_rules(type)


# ---- 靜態檔案（SDK下載）----
@app.get("/files/{file_path:path}")
def serve_file(file_path: str):
    """提供 SDK 下載"""
    import os
    from fastapi.responses import FileResponse
    
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
    full_path = os.path.normpath(os.path.join(base, file_path))
    
    # Security: 確保在 static 目錄內
    if not full_path.startswith(os.path.normpath(base)):
        from fastapi import HTTPException
        raise HTTPException(403, "Access denied")
    
    if not os.path.exists(full_path) or not os.path.isfile(full_path):
        from fastapi import HTTPException
        raise HTTPException(404, "File not found")
    
    return FileResponse(full_path)

# ===== Main =====
if __name__ == "__main__":
    print("🦐💥 COGITO-Swarm v4.1 Shared State Server 啟動中...")
    print(f"   DB: {DB_PATH}")
    print(f"   Port: 18787")
    print(f"   群組成員:")
    print(f"     - 爆蝦 @MbaM32026_bot (主持人)")
    print(f"     - 大爆蝦 @Mac2024_bot (成員)")
    print(f"     - 小爆蝦 @openclaw_ericsu_bot_bot (成員)")
    print(f"   🧭 /api/classify 規則路由器: v4.1 ✅")
    print(f"   🔒 LOCK: chat_id:message_id ✅")
    print(f"   PUSH callback: 已啟用 ✅")
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=18787)

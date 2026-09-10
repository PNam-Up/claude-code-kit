#!/bin/bash
# ─────────────────────────────────────────────
#  텔레그램 ↔ Claude Code 브릿지 (macOS)
#
#  의존성 없음 — curl 과 plutil 은 macOS 기본 탑재다.
#  (plutil 이 JSON 을 그대로 읽는다: plutil -extract ... raw -o - 파일)
#
#  설정은 ~/.claude-telegram-bridge/config.env 에서 읽는다.
#  토큰을 이 파일에 적지 마라.
# ─────────────────────────────────────────────
set -u

CONF_DIR="$HOME/.claude-telegram-bridge"
CONF="$CONF_DIR/config.env"
OFFSET_FILE="$CONF_DIR/offset"
LOG="$CONF_DIR/bridge.log"

[ -f "$CONF" ] || { echo "설정 파일이 없습니다: $CONF"; exit 1; }
# shellcheck disable=SC1090
. "$CONF"

: "${TELEGRAM_BOT_TOKEN:?토큰이 비어 있습니다}"
: "${TELEGRAM_CHAT_ID:?chat_id 가 비어 있습니다}"
WORK_DIR="${CLAUDE_WORKDIR:-$HOME}"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"

log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

json() {   # json <파일> <키경로>
  plutil -extract "$2" raw -o - "$1" 2>/dev/null
}

send() {   # send <텍스트>
  # 텔레그램 한 메시지 상한이 4096자라 잘라 보낸다.
  local text="$1"
  while [ -n "$text" ]; do
    curl -s --max-time 30 -X POST "$API/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" \
      --data-urlencode "text=${text:0:3900}" >/dev/null
    text="${text:3900}"
  done
}

# 텔레그램은 봇당 getUpdates 소비자가 하나뿐이다. 두 번 뜨면 409 로 양쪽 다 먹통이 된다.
# (설치기를 두 번 돌리면 그대로 재현된다 — 2026-09-10 실측)
LOCK="$CONF_DIR/bridge.lock"
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  log "이미 실행 중(PID $(cat "$LOCK")) — 중복 실행을 막고 종료한다"
  exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM

OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)
log "브릿지 시작 (workdir=$WORK_DIR)"
send "🤖 AI 비서가 연결됐습니다. 메시지를 보내보세요."

TMP="$CONF_DIR/.updates.json"
while true; do
  if ! curl -s --max-time 60 "$API/getUpdates" \
        -d offset="$OFFSET" -d timeout=30 -d allowed_updates='["message"]' \
        -o "$TMP"; then
    sleep 5; continue
  fi
  if [ "$(json "$TMP" ok)" != "true" ]; then
    if grep -q '"error_code":409' "$TMP" 2>/dev/null; then
      log "409 — 같은 봇을 쓰는 다른 인스턴스가 있다. 하나만 남겨야 한다"
      sleep 15
    else
      log "getUpdates 실패: $(head -c 120 "$TMP")"
      sleep 5
    fi
    continue
  fi

  N=$(json "$TMP" result)
  [ -z "$N" ] && N=0
  i=0
  while [ "$i" -lt "$N" ]; do
    UID_=$(json "$TMP" "result.$i.update_id")
    CHAT=$(json "$TMP" "result.$i.message.chat.id")
    TEXT=$(json "$TMP" "result.$i.message.text")
    i=$((i + 1))
    [ -n "$UID_" ] && OFFSET=$((UID_ + 1)) && echo "$OFFSET" > "$OFFSET_FILE"
    [ -z "$TEXT" ] && continue
    # 주인 외의 메시지는 무시한다. 이게 유일한 접근 통제다.
    if [ "$CHAT" != "$TELEGRAM_CHAT_ID" ]; then
      log "무시: 등록되지 않은 chat_id=$CHAT"
      continue
    fi
    log "요청: ${TEXT:0:80}"
    curl -s --max-time 10 -X POST "$API/sendChatAction" \
      -d chat_id="$TELEGRAM_CHAT_ID" -d action=typing >/dev/null
    OUT=$(cd "$WORK_DIR" && "$CLAUDE_BIN" --permission-mode bypassPermissions \
            --print "$TEXT" 2>&1)
    [ -z "$OUT" ] && OUT="(응답이 비었습니다)"
    send "$OUT"
    log "응답 ${#OUT}자"
  done
done

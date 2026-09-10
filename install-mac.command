#!/bin/bash
# ─────────────────────────────────────────────
#  Claude Code 설치기 — macOS
#  더블클릭하면 터미널에서 실행됩니다.
#
#  도구 선택(Gemini/Codex)은 2026-09-10 제거했다.
#  고를 게 있으면 초보자는 거기서 멈춘다. 예전 다중 설치본은
#  _backup_20260910_multi/ 에 그대로 있다.
# ─────────────────────────────────────────────
set -u

BOLD=$'\033[1m'; DIM=$'\033[2m'; OK=$'\033[32m'; WARN=$'\033[33m'; ERR=$'\033[31m'; OFF=$'\033[0m'

STEP_NO=0
STEP_TOTAL=2   # 설치 + 경로. 텔레그램은 선택이라 단계에 안 넣는다
STEP_START=0

# ── 진행 표시 ────────────────────────────────────────
# 사용자가 "멈춘 건가?" 하고 창을 닫아버리는 일을 막는다.
step() {   # step "제목" "예상시간"
  STEP_NO=$((STEP_NO + 1))
  STEP_START=$(date +%s)
  echo ""
  echo "  ${BOLD}[${STEP_NO}/${STEP_TOTAL}] $1${OFF}"
  if [ -n "$2" ]; then
    echo "        ${DIM}예상 $2 · 진행 중에는 화면이 멈춘 것처럼 보일 수 있습니다${OFF}"
    echo "        ${DIM}(설치가 진행 중이니 창을 닫지 마세요)${OFF}"
  fi
}

step_done() {   # step_done ok|fail
  el=$(( $(date +%s) - STEP_START ))
  t="$((el / 60))분 $((el % 60))초"
  if [ "$1" = "fail" ]; then echo "        ${ERR}실패 ($t)${OFF}"
  else echo "        ${OK}완료 ($t)${OFF}"; fi
}

ask() {   # ask "질문"  -> 답이 $REPLY_ANS 로
  echo ""
  echo "  ${BOLD}=============================================${OFF}"
  echo "   ${BOLD}[입력 필요] 아래에 답해 주세요${OFF}"
  echo "  ${BOLD}=============================================${OFF}"
  read -r -p "  $1" REPLY_ANS
}

echo ""
echo "  ${BOLD}🤖  AI 비서 설치 — Claude Code${OFF}"
echo "  ─────────────────────────────────────────────"
echo "  터미널에서 대화하듯 명령하면 파일 정리·자동화·문서 작성까지"
echo "  대신 해주는 AI 비서를 설치합니다."
echo ""
echo "  ${WARN}⚠️  유료 Claude 계정(Pro/Max)이 필요합니다. 무료 플랜으로는 작동하지 않습니다.${OFF}"
echo "  ${DIM}    계정은 본인 것을 사용합니다 — 설치기는 계정을 만들어 주지 않습니다.${OFF}"
echo ""
echo "  ${BOLD}총 ${STEP_TOTAL}단계로 진행합니다.${OFF}"

# ── 1. 설치 ──────────────────────────────────────────
step "Claude Code 설치" "1~3분"
if curl -fsSL https://claude.ai/install.sh | bash; then
  step_done ok
else
  step_done fail
  echo "  ${ERR}설치에 실패했습니다.${OFF}"
  echo "  ${DIM}Homebrew 사용자는:  brew install --cask claude-code${OFF}"
fi

# ── 2. PATH 보정 ─────────────────────────────────────
# 설치기가 PATH 를 등록해도 '지금 이 창'에는 반영되지 않는다.
# 이걸 안 하면 바로 아래 로그인 단계에서 command not found 가 난다.
step "경로 등록 및 확인" ""
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
  step_done ok
  echo "    ${OK}✅ Claude Code${OFF}  ${DIM}$(command -v claude)${OFF}"
else
  step_done fail
  echo "  ${WARN}이 창에서는 아직 인식되지 않습니다.${OFF}"
  echo "  ${WARN}터미널을 완전히 종료한 뒤 새로 열면 잡힙니다.${OFF}"
fi

# ── 로그인 ───────────────────────────────────────────
# OAuth 는 자동화할 수 없다(브라우저 승인 필요). 창만 대신 띄운다.
if command -v claude >/dev/null 2>&1; then
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  ${BOLD}이어서 로그인을 진행합니다.${OFF}"
  echo "    브라우저에서 Claude 로그인 화면이 열립니다."
  echo ""
  if [ "${AUTO:-0}" = "1" ]; then
    ANS="y"
  else
    ask "지금 로그인할까요? (그냥 Enter 치면 진행) "; ANS="$REPLY_ANS"
  fi
  case "$ANS" in
    [nN]*) echo "  나중에 터미널에서 'claude' 를 입력하면 됩니다." ;;
    *)     echo "  로그인을 진행하세요..."; claude ;;
  esac
fi

# ── 3. 텔레그램 연결 (선택) ──────────────────────────
# 봇 토큰은 스크립트에 넣지 않는다. config.env(0600) 에만 둔다.
setup_telegram() {
  CONF_DIR="$HOME/.claude-telegram-bridge"
  mkdir -p "$CONF_DIR"; chmod 700 "$CONF_DIR"

  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  ${BOLD}📱 텔레그램으로 원격 조종 (선택)${OFF}"
  echo ""
  echo "  폰에서 메시지를 보내면 이 PC 의 AI 비서가 답합니다."
  echo ""
  echo "  ${WARN}⚠️  보안 안내${OFF}"
  echo "  ${DIM}   연결하면 텔레그램으로 이 PC 의 파일을 읽고 쓰고 명령을 실행할 수 있습니다.${OFF}"
  echo "  ${DIM}   본인 계정(chat_id)에서 온 메시지만 처리하지만, 봇 토큰이 유출되면 위험합니다.${OFF}"
  echo "  ${DIM}   토큰을 남에게 보여주지 마세요. 건너뛰어도 Claude Code 는 정상 작동합니다.${OFF}"
  echo ""
  echo "  ${BOLD}봇 만드는 법${OFF}"
  echo "    1) 텔레그램에서 ${BOLD}@BotFather${OFF} 검색 → 대화 시작"
  echo "    2) ${BOLD}/newbot${OFF} 입력 → 이름·아이디 정하기"
  echo "    3) 받은 토큰(${DIM}123456:AAE...${OFF})을 아래에 붙여넣기"
  echo ""
  ask "봇 토큰 (건너뛰려면 그냥 Enter) : "; TOKEN="$REPLY_ANS"
  if [ -z "$TOKEN" ]; then
    echo "  ${DIM}건너뜁니다. 나중에 이 설치기를 다시 실행하면 연결할 수 있습니다.${OFF}"
    return
  fi

  API="https://api.telegram.org/bot${TOKEN}"
  BOTNAME=$(curl -s --max-time 20 "$API/getMe" | plutil -extract result.username raw -o - - 2>/dev/null)
  if [ -z "$BOTNAME" ]; then
    echo "  ${ERR}❌ 토큰이 올바르지 않습니다. 다시 확인해 주세요.${OFF}"
    return
  fi
  echo "  ${OK}✅ 봇 확인: @${BOTNAME}${OFF}"

  # chat_id 는 사용자가 직접 찾기 어렵다. 봇에게 아무 말이나 시키고 잡아낸다.
  echo ""
  echo "  ${BOLD}이제 텔레그램에서 @${BOTNAME} 에게 아무 메시지나 보내주세요.${OFF}"
  echo "  ${DIM}   (예: 안녕) — 보내면 자동으로 인식합니다. 최대 90초 기다립니다.${OFF}"
  CHAT_ID=""
  for _ in $(seq 1 30); do
    R=$(curl -s --max-time 10 "$API/getUpdates" -d timeout=3 2>/dev/null)
    echo "$R" > "$CONF_DIR/.probe.json"
    CHAT_ID=$(plutil -extract result.0.message.chat.id raw -o - "$CONF_DIR/.probe.json" 2>/dev/null)
    [ -n "$CHAT_ID" ] && break
    printf "."
  done
  rm -f "$CONF_DIR/.probe.json"
  echo ""
  if [ -z "$CHAT_ID" ]; then
    echo "  ${ERR}❌ 메시지를 받지 못했습니다. 설치기를 다시 실행해 주세요.${OFF}"
    return
  fi
  echo "  ${OK}✅ 사용자 확인 (chat_id: ${CHAT_ID})${OFF}"

  ask "AI 비서가 작업할 기본 폴더 (그냥 Enter 치면 홈 폴더) : "; WD="$REPLY_ANS"
  WD="${WD:-$HOME}"

  cat > "$CONF_DIR/config.env" <<EOF
TELEGRAM_BOT_TOKEN="${TOKEN}"
TELEGRAM_CHAT_ID="${CHAT_ID}"
CLAUDE_WORKDIR="${WD}"
CLAUDE_BIN="$(command -v claude)"
EOF
  chmod 600 "$CONF_DIR/config.env"

  cp "$(dirname "$0")/bridge/bridge-mac.sh" "$CONF_DIR/bridge.sh" 2>/dev/null
  chmod +x "$CONF_DIR/bridge.sh"

  PLIST="$HOME/Library/LaunchAgents/com.claudekit.telegram-bridge.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.claudekit.telegram-bridge</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>${CONF_DIR}/bridge.sh</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>${CONF_DIR}/bridge.err</string>
</dict></plist>
EOF
  launchctl unload "$PLIST" 2>/dev/null
  if launchctl load "$PLIST" 2>/dev/null; then
    echo "  ${OK}✅ 연결 완료 — 부팅할 때마다 자동 실행됩니다.${OFF}"
    echo "  ${DIM}   폰에서 @${BOTNAME} 에게 말을 걸어보세요.${OFF}"
  else
    echo "  ${WARN}⚠️  자동 실행 등록에 실패했습니다. 수동 실행: bash ${CONF_DIR}/bridge.sh${OFF}"
  fi
}

if command -v claude >/dev/null 2>&1; then
  setup_telegram
fi

echo ""
echo "  ${BOLD}다음 단계${OFF}"
echo "    · 다시 쓸 때는 터미널을 열고 ${BOLD}claude${OFF} 만 입력하면 됩니다."
echo "    · 정리하고 싶은 폴더로 이동한 뒤 실행하세요."
echo ""
echo "        cd ~/Desktop/내폴더"
echo "        claude"
echo ""
echo "    · 그다음엔 그냥 한국어로 말을 걸면 됩니다."
echo "        ${DIM}\"이 폴더 엑셀 파일들 요약해서 표로 정리해줘\"${OFF}"
echo ""
echo "  ${BOLD}잘 안 될 때${OFF}"
echo "    ${DIM}· 'claude' 를 못 찾음  → 터미널을 완전히 종료 후 다시 열기${OFF}"
echo "    ${DIM}· 로그인이 거부됨      → 무료 플랜입니다. Pro/Max 필요${OFF}"
echo "    ${DIM}· 회사 PC 에서 차단    → 보안 정책. IT 담당자 문의${OFF}"
echo ""
read -r -p "  Enter 키를 누르면 닫힙니다 ... " _

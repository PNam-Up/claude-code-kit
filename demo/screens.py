#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""설치 단계별 화면 이미지를 만든다 (영상 촬영용).

실제 설치기의 출력을 그대로 옮겨 적었다. 화면은 누적된다 — 진짜 터미널처럼
앞 단계가 위로 밀려 올라가고, 넘치면 마지막 화면분만 보인다.
"""
import os
from make_screens import render

MAX_LINES = 23
buf = []
shots = []


def norm(l):
    """한 줄을 [(글자, 색), ...] 형태로 맞춘다."""
    if isinstance(l, str):
        return [(l, "fg")]
    if isinstance(l, tuple):
        return [l]
    if len(l) == 2 and all(isinstance(x, str) for x in l):
        return [(l[0], l[1])]      # ["문장", "색"]
    return [x if isinstance(x, tuple) else (x, "fg") for x in l]


def add(*lines):
    for l in lines:
        buf.append(norm(l))


def shot(os_name, name, title):
    view = buf[-MAX_LINES:]
    shots.append(render(os_name, name, view, title))


def clear():
    buf.clear()


DASH = "  ─────────────────────────────────────────────"
ASK = [
    "",
    ["  =============================================", "white"],
    ["   [입력 필요] 아래에 답해 주세요", "white"],
    ["  =============================================", "white"],
]

# ── macOS ────────────────────────────────────────────
T = "Terminal — install-mac.command"
add(["  🤖  AI 비서 설치 — Claude Code", "white"], DASH,
    "  터미널에서 대화하듯 명령하면 파일 정리·자동화·문서 작성까지",
    "  대신 해주는 AI 비서를 설치합니다.", "",
    ["  ⚠️  유료 Claude 계정(Pro/Max)이 필요합니다. 무료 플랜으로는 작동하지 않습니다.", "yellow"],
    ["      계정은 본인 것을 사용합니다 — 설치기는 계정을 만들어 주지 않습니다.", "dim"], "",
    ["  총 2단계로 진행합니다.", "white"])
shot("mac", "01-start", T)

add("", ["  [1/2] Claude Code 설치", "white"],
    ["        예상 1~3분 · 진행 중에는 화면이 멈춘 것처럼 보일 수 있습니다", "dim"],
    ["        (설치가 진행 중이니 창을 닫지 마세요)", "dim"])
shot("mac", "02-installing", T)

add(["        완료 (1분 42초)", "green"])
shot("mac", "03-install-done", T)

add("", ["  [2/2] 경로 등록 및 확인", "white"], ["        완료 (0분 0초)", "green"],
    [("    ✅ Claude Code", "green"), ("  /Users/you/.local/bin/claude", "dim")])
shot("mac", "04-path", T)

add("", DASH, ["  이어서 로그인을 진행합니다.", "white"],
    "    브라우저에서 Claude 로그인 화면이 열립니다.", *ASK,
    ["  지금 로그인할까요? (그냥 Enter 치면 진행) ▏", "white"])
shot("mac", "05-login", T)

clear()
add("", DASH, ["  📱 텔레그램으로 원격 조종 (선택)", "white"], "",
    "  폰에서 메시지를 보내면 이 PC 의 AI 비서가 답합니다.", "",
    ["  ⚠️  보안 안내", "yellow"],
    ["     연결하면 텔레그램으로 이 PC 의 파일을 읽고 쓰고 명령을 실행할 수 있습니다.", "dim"],
    ["     본인 계정(chat_id)에서 온 메시지만 처리하지만, 봇 토큰이 유출되면 위험합니다.", "dim"],
    ["     토큰을 남에게 보여주지 마세요. 건너뛰어도 Claude Code 는 정상 작동합니다.", "dim"], "",
    ["  봇 만드는 법", "white"],
    ["    1) 텔레그램에서 @BotFather 검색 → 대화 시작", "fg"],
    ["    2) /newbot 입력 → 이름·아이디 정하기", "fg"],
    ["    3) 받은 토큰(123456:AAE...)을 아래에 붙여넣기", "fg"])
shot("mac", "06-telegram-intro", T)

add(*ASK, ["  봇 토큰 (건너뛰려면 그냥 Enter) : ▏", "white"])
shot("mac", "07-token-input", T)

add(["  ✅ 봇 확인: @my_assistant_bot", "green"], "",
    ["  이제 텔레그램에서 @my_assistant_bot 에게 아무 메시지나 보내주세요.", "white"],
    ["     (예: 안녕) — 보내면 자동으로 인식합니다. 최대 90초 기다립니다.", "dim"],
    "  ....")
shot("mac", "08-wait-message", T)

add(["  ✅ 사용자 확인 (chat_id: 8624736511)", "green"], *ASK,
    ["  AI 비서가 작업할 기본 폴더 (그냥 Enter 치면 홈 폴더) : ▏", "white"])
shot("mac", "09-chatid", T)

add(["  ✅ 연결 완료 — 부팅할 때마다 자동 실행됩니다.", "green"],
    ["     폰에서 @my_assistant_bot 에게 말을 걸어보세요.", "dim"])
shot("mac", "10-connected", T)

clear()
add("", ["  다음 단계", "white"],
    "    · 다시 쓸 때는 터미널을 열고 claude 만 입력하면 됩니다.",
    "    · 정리하고 싶은 폴더로 이동한 뒤 실행하세요.", "",
    ["        cd ~/Desktop/내폴더", "cyan"], ["        claude", "cyan"], "",
    "    · 그다음엔 그냥 한국어로 말을 걸면 됩니다.",
    ['        "이 폴더 엑셀 파일들 요약해서 표로 정리해줘"', "dim"], "",
    ["  잘 안 될 때", "white"],
    ["    · 'claude' 를 못 찾음  → 터미널을 완전히 종료 후 다시 열기", "dim"],
    ["    · 로그인이 거부됨      → 무료 플랜입니다. Pro/Max 필요", "dim"],
    ["    · 회사 PC 에서 차단    → 보안 정책. IT 담당자 문의", "dim"])
shot("mac", "11-next-steps", T)

# ── Windows ──────────────────────────────────────────
clear()
W = "Windows PowerShell — install-windows.ps1"
add("", ["  AI 비서 설치 - Claude Code", "cyan"],
    "  ---------------------------------------------",
    "  터미널에서 대화하듯 명령하면 파일 정리 · 자동화 · 문서 작성까지",
    "  대신 해주는 AI 비서를 설치합니다.", "",
    ["  [주의] 유료 Claude 계정(Pro/Max)이 필요합니다. 무료 플랜은 작동하지 않습니다.", "yellow"],
    ["         계정은 본인 것을 사용합니다 - 설치기는 계정을 만들어 주지 않습니다.", "dim"], "",
    ["  [사전작업] PowerShell 실행정책을 RemoteSigned 로 변경했습니다.", "dim"], "",
    ["  총 3단계로 진행합니다.", "cyan"])
shot("win", "01-start", W)

add("", ["  [1/3] Claude Code 설치", "cyan"],
    ["        예상 1~3분 · 진행 중에는 화면이 멈춘 것처럼 보일 수 있습니다", "dim"],
    ["        (설치가 진행 중이니 창을 닫지 마세요)", "dim"])
shot("win", "02-installing", W)

add(["        완료 (2분 08초)", "green"], "",
    ["  [2/3] 경로 등록 및 확인", "cyan"],
    ["  [PATH 등록] C:\\Users\\you\\.local\\bin", "green"],
    ["        완료 (0분 0초)", "green"],
    ["    OK  Claude Code   C:\\Users\\you\\.local\\bin\\claude.exe", "green"])
shot("win", "03-path", W)

add("", ["  [3/3] 로그인", "cyan"],
    "    새 창이 열리고 브라우저에서 로그인 화면이 나옵니다.", *ASK,
    ["  지금 로그인할까요? (그냥 Enter 치면 진행) ▏", "white"])
shot("win", "04-login", W)

clear()
add("", "  ---------------------------------------------",
    ["  [선택] 텔레그램으로 원격 조종", "cyan"], "",
    "  폰에서 메시지를 보내면 이 PC 의 AI 비서가 답합니다.", "",
    ["  [보안 안내]", "yellow"],
    ["     연결하면 텔레그램으로 이 PC 의 파일을 읽고 쓰고 명령을 실행할 수 있습니다.", "dim"],
    ["     본인 계정(chat_id)에서 온 메시지만 처리하지만, 봇 토큰이 유출되면 위험합니다.", "dim"],
    ["     토큰을 남에게 보여주지 마세요. 건너뛰어도 Claude Code 는 정상 작동합니다.", "dim"], "",
    ["  봇 만드는 법", "cyan"],
    "    1) 텔레그램에서 @BotFather 검색 -> 대화 시작",
    "    2) /newbot 입력 -> 이름/아이디 정하기",
    "    3) 받은 토큰(123456:AAE...)을 아래에 붙여넣기")
shot("win", "05-telegram-intro", W)

add(*ASK, ["  봇 토큰 (건너뛰려면 그냥 Enter) : ▏", "white"])
shot("win", "06-token-input", W)

add(["  OK  봇 확인: @my_assistant_bot", "green"], "",
    ["  이제 텔레그램에서 @my_assistant_bot 에게 아무 메시지나 보내주세요.", "cyan"],
    ["     (예: 안녕) - 보내면 자동으로 인식합니다. 최대 90초 기다립니다.", "dim"],
    "  ....")
shot("win", "07-wait-message", W)

add(["  OK  사용자 확인 (chat_id: 8624736511)", "green"], *ASK,
    ["  AI 비서가 작업할 기본 폴더 (그냥 Enter 치면 홈 폴더) : ▏", "white"])
shot("win", "08-chatid", W)

add(["  OK  연결 완료 - 로그인할 때마다 자동 실행됩니다.", "green"],
    ["     폰에서 @my_assistant_bot 에게 말을 걸어보세요.", "dim"])
shot("win", "09-connected", W)

clear()
add("", ["  다음 단계", "cyan"],
    "    · 다시 쓸 때는 터미널을 열고  claude  만 입력하면 됩니다.",
    "    · 정리하고 싶은 폴더로 이동한 뒤 실행하세요.", "",
    ["        cd %USERPROFILE%\\Desktop\\내폴더", "cyan"], ["        claude", "cyan"], "",
    ["  잘 안 될 때", "cyan"],
    ["    · 'claude 를 찾을 수 없습니다'  -> 터미널 완전 종료 후 재실행", "dim"],
    ["    · 'npm 을 실행할 수 없습니다'   -> 창 닫고 다시 실행 (실행정책 반영됨)", "dim"],
    ["    · 로그인이 거부됨               -> 무료 플랜입니다. Pro/Max 필요", "dim"],
    ["    · 회사 PC 에서 설치 차단        -> IT 담당자에게 문의 필요", "dim"])
shot("win", "10-next-steps", W)

print(f"{len(shots)}장 생성")
for s in shots:
    print("  " + os.path.basename(s))

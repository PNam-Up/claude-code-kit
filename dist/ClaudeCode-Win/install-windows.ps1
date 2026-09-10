param(
  [switch]$Auto,           # 질문 없이 끝까지 자동 진행
  [switch]$Elevated        # 관리자 권한으로 재실행된 회차 (무한 재실행 방지)
)

# ─────────────────────────────────────────────
#  Claude Code 설치기 — Windows
#  install-windows.bat 을 더블클릭해서 실행하세요
#
#  도구 선택(Gemini/Codex)은 2026-09-10 제거했다.
#  예전 다중 설치본은 _backup_20260910_multi\ 에 있다.
# ─────────────────────────────────────────────
$ErrorActionPreference = "Continue"

function Say($t, $c = "White") { Write-Host $t -ForegroundColor $c }

$script:StepNo = 0
$script:StepTotal = 3
$script:StepStart = Get-Date

# ── 진행 표시 ────────────────────────────────────────
# 사용자가 "멈춘 건가?" 하고 창을 닫아버리는 일을 막는다.
function Step($title, $eta) {
  $script:StepNo++
  $script:StepStart = Get-Date
  Say ""
  Say ("  [{0}/{1}] {2}" -f $script:StepNo, $script:StepTotal, $title) "Cyan"
  if ($eta) {
    Say ("        예상 {0} · 진행 중에는 화면이 멈춘 것처럼 보일 수 있습니다" -f $eta) "DarkGray"
    Say ("        (설치가 진행 중이니 창을 닫지 마세요)") "DarkGray"
  }
}

function StepDone($ok = $true) {
  $el = (Get-Date) - $script:StepStart
  $t = "{0}분 {1}초" -f [int]$el.TotalMinutes, $el.Seconds
  if ($ok) { Say ("        완료 ({0})" -f $t) "Green" }
  else     { Say ("        실패 ({0})" -f $t) "Red" }
}

function Ask($msg) {
  Say ""
  Say "  =============================================" "Yellow"
  Say "   [입력 필요] 아래에 답해 주세요" "Yellow"
  Say "  =============================================" "Yellow"
  return (Read-Host ("  " + $msg))
}

Say ""
Say "  AI 비서 설치 - Claude Code" "Cyan"
Say "  ---------------------------------------------"
Say "  터미널에서 대화하듯 명령하면 파일 정리 · 자동화 · 문서 작성까지"
Say "  대신 해주는 AI 비서를 설치합니다."
Say ""
Say "  [주의] 유료 Claude 계정(Pro/Max)이 필요합니다. 무료 플랜은 작동하지 않습니다." "Yellow"
Say "         계정은 본인 것을 사용합니다 - 설치기는 계정을 만들어 주지 않습니다." "DarkGray"
Say ""
Say ("  총 {0}단계로 진행합니다." -f $script:StepTotal) "Cyan"

# ── 사전 정리: PowerShell 실행정책 ───────────────────
# npm 이 설치하는 .ps1 shim 이 차단되는 문제를 미리 푼다 (가장 흔한 실패 원인)
try {
  $pol = Get-ExecutionPolicy -Scope CurrentUser
  if ($pol -eq "Restricted" -or $pol -eq "Undefined" -or $pol -eq "AllSigned") {
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
    Say "  [사전작업] PowerShell 실행정책을 RemoteSigned 로 변경했습니다." "DarkGray"
  }
} catch {
  Say "  [사전작업] 실행정책 변경 실패 - 설치 후 npm 명령이 막히면 아래를 직접 실행하세요:" "Yellow"
  Say "             Set-ExecutionPolicy -Scope CurrentUser RemoteSigned" "Yellow"
}

# ── 관리자 권한 ──────────────────────────────────────
# 공식 설치본은 %USERPROFILE% 안에만 쓰므로 원칙적으로는 승격이 필요 없다.
# 그런데 실제로 "권한이 없다"며 막히는 환경이 있다(정책·백신·기존 npm 설치본 등).
# 그래서 관리자 계정이면 UAC 로 한 번 승격해 다시 실행한다.
#
# ⚠️ 승격 시 '다른 관리자 계정'으로 인증하면 설치가 그 계정 폴더로 들어간다.
#    그래서 현재 계정이 관리자 그룹일 때만 권한다(같은 계정 UAC 승격 = 경로 유지).
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = ([Security.Principal.WindowsPrincipal]$id).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)

function Test-AccountIsAdmin {
  # 승격 전에도 '이 계정이 관리자 그룹인가'를 본다. SID S-1-5-32-544 = Administrators
  try {
    $grp = ([ADSI]"WinNT://./Administrators,group")
    $members = @($grp.psbase.Invoke("Members")) | ForEach-Object {
      $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
    }
    return ($members -contains $env:USERNAME)
  } catch { return $false }
}

if (-not $isElevated -and -not $Elevated) {
  if (Test-AccountIsAdmin) {
    Say ""
    Say "  [안내] 일부 환경에서 권한 문제로 설치가 막힙니다." "Yellow"
    Say "         관리자 권한으로 다시 실행하면 대부분 해결됩니다." "Yellow"
    Say "         (지금 계정 그대로 승격되므로 설치 위치는 바뀌지 않습니다)" "DarkGray"
    $yn = if ($Auto) { "y" } else { Ask "관리자 권한으로 다시 실행할까요? (그냥 Enter 치면 진행) " }
    if ($yn -notmatch '^[nN]') {
      $argv = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Elevated")
      if ($Auto) { $argv += "-Auto" }
      try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argv | Out-Null
        Say "  관리자 창으로 넘어갑니다. 이 창은 닫으셔도 됩니다." "Green"
        Start-Sleep -Seconds 3
        exit 0
      } catch {
        Say "  승격이 취소됐습니다. 일반 권한으로 계속합니다." "Yellow"
      }
    }
  } else {
    Say ""
    Say "  [안내] 관리자 권한이 없는 계정입니다. 그대로 진행합니다." "DarkGray"
    Say "         권한 오류가 나면 관리자에게 문의가 필요합니다." "DarkGray"
  }
}

function Ensure-Path {
  # 설치기가 PATH 를 등록하지 않는 경우가 있어 직접 넣는다.
  # (Claude Code 네이티브 설치본은 ~\.local\bin, npm 전역은 %APPDATA%\npm)
  $targets = @("$env:USERPROFILE\.local\bin", "$env:APPDATA\npm")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $user) { $user = "" }
  $added = @()
  foreach ($t in $targets) {
    if (-not (Test-Path $t)) { continue }
    if ($user -notlike "*$t*") {
      $user = ($user.TrimEnd(';') + ";" + $t).TrimStart(';')
      $added += $t
    }
    if ($env:Path -notlike "*$t*") { $env:Path = $env:Path.TrimEnd(';') + ";" + $t }
  }
  if ($added.Count -gt 0) {
    [Environment]::SetEnvironmentVariable("Path", $user, "User")
    foreach ($a in $added) { Say ("  [PATH 등록] " + $a) "Green" }
  }
}


function Install-Claude {
  Say ""
  Step "Claude Code 설치" "1~3분"
  try {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    StepDone $true
  } catch {
    StepDone $false
    Say "  설치에 실패했습니다. 대안:  winget install Anthropic.ClaudeCode" "Red"
  }
}

Install-Claude

# ── PATH 보정 ────────────────────────────────────────
# 설치기가 PATH 를 등록해도 '지금 이 창'에는 반영되지 않는다.
Step "경로 등록 및 확인" $null
Ensure-Path
$cmdPath = Get-Command claude -ErrorAction SilentlyContinue
if ($cmdPath) {
  StepDone $true
  Say ("    OK  Claude Code   " + $cmdPath.Source) "Green"
} else {
  StepDone $false
  Say "    이 창에서는 아직 인식되지 않습니다." "Yellow"
  Say "    창을 닫고 터미널을 새로 열면 잡힙니다." "Yellow"
}

# ── 로그인 ───────────────────────────────────────────
# OAuth 는 자동화할 수 없다(브라우저 승인 필요). 창만 대신 띄운다.
Step "로그인" $null
if ($cmdPath) {
  Say "    새 창이 열리고 브라우저에서 로그인 화면이 나옵니다."
  $go = $true
  if (-not $Auto) {
    $ans = Ask "지금 로그인할까요? (그냥 Enter 치면 진행) "
    if ($ans -match '^[nN]') { $go = $false }
  }
  if ($go) {
    Start-Process "powershell.exe" -ArgumentList @(
      "-NoExit", "-NoProfile", "-Command",
      "`$env:Path='$($env:Path)'; Write-Host '  로그인을 진행하세요...' -ForegroundColor Cyan; & '$($cmdPath.Source)'"
    ) | Out-Null
    StepDone $true
    Say "  로그인 창을 열었습니다." "Green"
  } else {
    StepDone $true
    Say "  나중에 터미널에서 'claude' 를 입력하면 로그인할 수 있습니다." "Yellow"
  }
} else {
  StepDone $false
  Say "  터미널을 새로 열고 'claude' 를 입력하면 로그인할 수 있습니다." "Yellow"
}

# ── 텔레그램 연결 (선택) ─────────────────────────────
# 봇 토큰은 스크립트에 넣지 않는다. config.env 에만 두고 ACL 로 막는다.
function Setup-Telegram {
  $confDir = Join-Path $env:USERPROFILE ".claude-telegram-bridge"
  New-Item -ItemType Directory -Force -Path $confDir | Out-Null

  Say ""
  Say "  ---------------------------------------------"
  Say "  [선택] 텔레그램으로 원격 조종" "Cyan"
  Say ""
  Say "  폰에서 메시지를 보내면 이 PC 의 AI 비서가 답합니다."
  Say ""
  Say "  [보안 안내]" "Yellow"
  Say "     연결하면 텔레그램으로 이 PC 의 파일을 읽고 쓰고 명령을 실행할 수 있습니다." "DarkGray"
  Say "     본인 계정(chat_id)에서 온 메시지만 처리하지만, 봇 토큰이 유출되면 위험합니다." "DarkGray"
  Say "     토큰을 남에게 보여주지 마세요. 건너뛰어도 Claude Code 는 정상 작동합니다." "DarkGray"
  Say ""
  Say "  봇 만드는 법" "Cyan"
  Say "    1) 텔레그램에서 @BotFather 검색 -> 대화 시작"
  Say "    2) /newbot 입력 -> 이름/아이디 정하기"
  Say "    3) 받은 토큰(123456:AAE...)을 아래에 붙여넣기"

  $token = Ask "봇 토큰 (건너뛰려면 그냥 Enter) : "
  if ([string]::IsNullOrWhiteSpace($token)) {
    Say "  건너뜁니다. 나중에 이 설치기를 다시 실행하면 연결할 수 있습니다." "DarkGray"
    return
  }
  $token = $token.Trim()
  $api = "https://api.telegram.org/bot$token"
  try {
    $me = Invoke-RestMethod -Uri "$api/getMe" -TimeoutSec 20
  } catch { $me = $null }
  if (-not $me -or -not $me.ok) {
    Say "  토큰이 올바르지 않습니다. 다시 확인해 주세요." "Red"
    return
  }
  $botName = $me.result.username
  Say ("  OK  봇 확인: @" + $botName) "Green"

  # chat_id 는 사용자가 직접 찾기 어렵다. 봇에게 말을 걸게 하고 잡아낸다.
  Say ""
  Say ("  이제 텔레그램에서 @" + $botName + " 에게 아무 메시지나 보내주세요.") "Cyan"
  Say "     (예: 안녕) - 보내면 자동으로 인식합니다. 최대 90초 기다립니다." "DarkGray"
  $chatId = $null
  for ($i = 0; $i -lt 30; $i++) {
    try {
      $r = Invoke-RestMethod -Uri "$api/getUpdates" -Method Post -TimeoutSec 10 -Body @{ timeout = 3 }
      if ($r.ok -and $r.result.Count -gt 0) { $chatId = $r.result[0].message.chat.id; break }
    } catch {}
    Write-Host "." -NoNewline
  }
  Say ""
  if (-not $chatId) {
    Say "  메시지를 받지 못했습니다. 설치기를 다시 실행해 주세요." "Red"
    return
  }
  Say ("  OK  사용자 확인 (chat_id: " + $chatId + ")") "Green"

  $wd = Ask "AI 비서가 작업할 기본 폴더 (그냥 Enter 치면 홈 폴더) : "
  if ([string]::IsNullOrWhiteSpace($wd)) { $wd = $env:USERPROFILE }

  $claudePath = (Get-Command claude -ErrorAction SilentlyContinue).Source
  $confFile = Join-Path $confDir "config.env"
  @(
    ('TELEGRAM_BOT_TOKEN="{0}"' -f $token),
    ('TELEGRAM_CHAT_ID="{0}"'   -f $chatId),
    ('CLAUDE_WORKDIR="{0}"'     -f $wd),
    ('CLAUDE_BIN="{0}"'         -f $claudePath)
  ) | Set-Content -Path $confFile -Encoding UTF8

  # 본인 계정만 읽을 수 있게 상속 끊고 권한 재설정
  icacls $confFile /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null

  $src = Join-Path $PSScriptRoot "bridge\bridge-windows.ps1"
  $dst = Join-Path $confDir "bridge.ps1"
  if (Test-Path $src) { Copy-Item $src $dst -Force }

  if (Test-Path $dst) {
    $action = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dst`""
    schtasks /Create /TN "ClaudeTelegramBridge" /TR $action /SC ONLOGON /F /RL LIMITED | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Start-Process powershell.exe -ArgumentList @("-NoProfile","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",$dst) | Out-Null
      Say "  OK  연결 완료 - 로그인할 때마다 자동 실행됩니다." "Green"
      Say ("     폰에서 @" + $botName + " 에게 말을 걸어보세요.") "DarkGray"
    } else {
      Say "  자동 실행 등록에 실패했습니다. 수동 실행:" "Yellow"
      Say ("     powershell -File " + $dst) "Yellow"
    }
  } else {
    Say "  bridge-windows.ps1 을 찾지 못했습니다. 키트 폴더째로 압축을 풀었는지 확인하세요." "Red"
  }
}

if ($cmdPath) { Setup-Telegram }

Say ""
Say "  다음 단계" "Cyan"
Say "    · 다시 쓸 때는 터미널을 열고  claude  만 입력하면 됩니다."
Say "    · 정리하고 싶은 폴더로 이동한 뒤 실행하세요."
Say ""
Say "        cd %USERPROFILE%\Desktop\내폴더"
Say "        claude"
Say ""
Say "    · 그다음엔 그냥 한국어로 말을 걸면 됩니다."
Say "        \"이 폴더 엑셀 파일들 요약해서 표로 정리해줘\"" "DarkGray"
Say ""
Say "  잘 안 될 때" "Cyan"
Say "    · 'claude 를 찾을 수 없습니다'  -> 터미널 완전 종료 후 재실행" "DarkGray"
Say "    · 'npm 을 실행할 수 없습니다'   -> 창 닫고 다시 실행 (실행정책 반영됨)" "DarkGray"
Say "    · 로그인이 거부됨               -> 무료 플랜입니다. Pro/Max 필요" "DarkGray"
Say "    · 회사 PC 에서 설치 차단        -> IT 담당자에게 문의 필요" "DarkGray"
Say ""
if (-not $Auto) { Read-Host "  Enter 키를 누르면 닫힙니다" } else { Start-Sleep -Seconds 3 }

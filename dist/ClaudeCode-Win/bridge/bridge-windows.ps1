# ─────────────────────────────────────────────
#  텔레그램 ↔ Claude Code 브릿지 (Windows)
#
#  의존성 없음 — PowerShell 의 Invoke-RestMethod / ConvertFrom-Json 만 쓴다.
#  설정은 %USERPROFILE%\.claude-telegram-bridge\config.env 에서 읽는다.
#  토큰을 이 파일에 적지 마라.
# ─────────────────────────────────────────────
$ErrorActionPreference = "Continue"

$ConfDir = Join-Path $env:USERPROFILE ".claude-telegram-bridge"
$Conf    = Join-Path $ConfDir "config.env"
$OffsetF = Join-Path $ConfDir "offset"
$LogF    = Join-Path $ConfDir "bridge.log"

if (-not (Test-Path $Conf)) { Write-Host "설정 파일이 없습니다: $Conf"; exit 1 }

$cfg = @{}
Get-Content $Conf | ForEach-Object {
  if ($_ -match '^\s*([A-Z_]+)\s*=\s*"?([^"]*)"?\s*$') { $cfg[$Matches[1]] = $Matches[2] }
}
$Token  = $cfg["TELEGRAM_BOT_TOKEN"]
$ChatId = $cfg["TELEGRAM_CHAT_ID"]
if (-not $Token -or -not $ChatId) { Write-Host "토큰 또는 chat_id 가 비었습니다."; exit 1 }

$WorkDir   = if ($cfg["CLAUDE_WORKDIR"]) { $cfg["CLAUDE_WORKDIR"] } else { $env:USERPROFILE }
$ClaudeBin = if ($cfg["CLAUDE_BIN"]) { $cfg["CLAUDE_BIN"] } else { "claude" }
$Api = "https://api.telegram.org/bot$Token"

function Log($m) { "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m | Add-Content $LogF }

function Send-Msg($text) {
  # 텔레그램 한 메시지 상한이 4096자라 잘라 보낸다.
  while ($text.Length -gt 0) {
    $chunk = $text.Substring(0, [Math]::Min(3900, $text.Length))
    try {
      Invoke-RestMethod -Uri "$Api/sendMessage" -Method Post -TimeoutSec 30 `
        -Body @{ chat_id = $ChatId; text = $chunk } | Out-Null
    } catch { Log "전송 실패: $_" }
    if ($text.Length -le 3900) { break }
    $text = $text.Substring(3900)
  }
}

# 텔레그램은 봇당 getUpdates 소비자가 하나뿐이다. 두 번 뜨면 409 로 양쪽 다 먹통이 된다.
$LockF = Join-Path $ConfDir "bridge.lock"
if (Test-Path $LockF) {
  $old = (Get-Content $LockF -Raw).Trim()
  if ($old -and (Get-Process -Id $old -ErrorAction SilentlyContinue)) {
    Log "이미 실행 중(PID $old) - 중복 실행을 막고 종료한다"
    exit 0
  }
}
Set-Content -Path $LockF -Value $PID

$offset = 0
if (Test-Path $OffsetF) { $offset = [int](Get-Content $OffsetF -Raw).Trim() }

Log "브릿지 시작 (workdir=$WorkDir)"
Send-Msg "🤖 AI 비서가 연결됐습니다. 메시지를 보내보세요."

while ($true) {
  try {
    $r = Invoke-RestMethod -Uri "$Api/getUpdates" -Method Post -TimeoutSec 60 `
          -Body @{ offset = $offset; timeout = 30; allowed_updates = '["message"]' }
  } catch { Start-Sleep -Seconds 5; continue }

  if (-not $r.ok) {
    if ($r.error_code -eq 409) {
      Log "409 - 같은 봇을 쓰는 다른 인스턴스가 있다. 하나만 남겨야 한다"
      Start-Sleep -Seconds 15
    } else {
      Log ("getUpdates 실패: " + $r.description)
      Start-Sleep -Seconds 5
    }
    continue
  }

  foreach ($u in $r.result) {
    $offset = $u.update_id + 1
    Set-Content -Path $OffsetF -Value $offset
    $msg = $u.message
    if (-not $msg -or -not $msg.text) { continue }
    # 주인 외의 메시지는 무시한다. 이게 유일한 접근 통제다.
    if ("$($msg.chat.id)" -ne "$ChatId") { Log "무시: 등록되지 않은 chat_id=$($msg.chat.id)"; continue }

    Log ("요청: " + $msg.text.Substring(0, [Math]::Min(80, $msg.text.Length)))
    try {
      Invoke-RestMethod -Uri "$Api/sendChatAction" -Method Post -TimeoutSec 10 `
        -Body @{ chat_id = $ChatId; action = "typing" } | Out-Null
    } catch {}

    Push-Location $WorkDir
    $out = & $ClaudeBin --permission-mode bypassPermissions --print $msg.text 2>&1 | Out-String
    Pop-Location

    if (-not $out -or $out.Trim() -eq "") { $out = "(응답이 비었습니다)" }
    Send-Msg $out.Trim()
    Log ("응답 " + $out.Length + "자")
  }
}

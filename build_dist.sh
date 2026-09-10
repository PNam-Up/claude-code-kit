#!/bin/bash
# 배포용 zip 을 만든다. dist/ 는 매번 새로 생성하므로 git 에 넣지 않는다.
# (루트 원본과 dist 를 둘 다 커밋하면 한쪽만 고치는 사고가 난다)
set -eu
cd "$(dirname "$0")"
rm -rf dist
mkdir -p dist/ClaudeCode-Mac/bridge dist/ClaudeCode-Win/bridge

cp install-mac.command dist/ClaudeCode-Mac/
cp bridge/bridge-mac.sh dist/ClaudeCode-Mac/bridge/
cp readme/README-mac.md dist/ClaudeCode-Mac/README.md
chmod +x dist/ClaudeCode-Mac/install-mac.command dist/ClaudeCode-Mac/bridge/bridge-mac.sh

cp install-windows.bat install-windows.ps1 dist/ClaudeCode-Win/
cp bridge/bridge-windows.ps1 dist/ClaudeCode-Win/bridge/
cp readme/README-win.md dist/ClaudeCode-Win/README.md

cd dist
zip -q -r -X ClaudeCode-Mac.zip ClaudeCode-Mac -x '.*'
zip -q -r -X ClaudeCode-Win.zip ClaudeCode-Win -x '.*'
ls -la *.zip

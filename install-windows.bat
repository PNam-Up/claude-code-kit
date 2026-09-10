@echo off
chcp 949 >nul
REM ---------------------------------------------
REM  AI 비서 설치기 - Windows (더블클릭 실행용)
REM  인자를 그대로 넘겨 무인 설치도 지원합니다.
REM    예) install-windows.bat -Tool gemini -Auto
REM ---------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1" %*

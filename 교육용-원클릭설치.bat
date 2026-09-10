@echo off
chcp 949 >nul
REM ---------------------------------------------
REM  교육용 원클릭 설치 - 질문 없이 Claude Code 까지 자동
REM  더블클릭만 하면 됩니다. 로그인만 마지막에 직접 하세요.
REM ---------------------------------------------
title AI 비서 설치 (자동)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1" -Auto

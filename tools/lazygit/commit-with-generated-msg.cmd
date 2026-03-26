@echo off
setlocal

set "TMPMSG=.git\lazygit-commit-msg.txt"

nvim --clean --headless "+lua dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')" +qa > "%TMPMSG%" 2>&1
if errorlevel 1 (
  echo failed to generate commit message
  if exist "%TMPMSG%" del "%TMPMSG%" >nul 2>&1
  exit /b 1
)

set "FIRST="
set /p FIRST=<"%TMPMSG%"
if "%FIRST%"=="" (
  echo failed to generate commit message
  if exist "%TMPMSG%" del "%TMPMSG%" >nul 2>&1
  exit /b 1
)

git commit -e -F "%TMPMSG%"
set "EC=%ERRORLEVEL%"

if exist "%TMPMSG%" del "%TMPMSG%" >nul 2>&1
exit /b %EC%

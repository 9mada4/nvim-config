@echo off
setlocal

set "TMPBASE=%TEMP%\nvim-commit-msg-%RANDOM%-%RANDOM%"
set "TMPMSG=%TMPBASE%.txt"
set "TMPERR=%TMPBASE%.err"

nvim --clean --headless "+lua dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')" +qa 1>"%TMPMSG%" 2>"%TMPERR%"
if errorlevel 1 goto :failed

set "FIRST="
set /p FIRST=<"%TMPMSG%"
if not defined FIRST goto :failed

git -c core.editor=nvim commit -e -F "%TMPMSG%"
set "EC=%ERRORLEVEL%"
goto :cleanup

:failed
echo failed to generate commit message
set "EC=1"

:cleanup
if exist "%TMPMSG%" del "%TMPMSG%" >nul 2>&1
if exist "%TMPERR%" del "%TMPERR%" >nul 2>&1
exit /b %EC%

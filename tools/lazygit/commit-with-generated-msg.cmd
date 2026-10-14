@echo off
setlocal
set "NVIM_GENERATE_COMMIT_MSG=1"
git -c core.editor=nvim commit
exit /b %ERRORLEVEL%

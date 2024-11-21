@echo off
setlocal
set BASEDIR=%~dp0
if exist "%BASEDIR%..\share\xmake\xmake.exe" (
    "%BASEDIR%..\share\xmake\xmake.exe" %*
)
endlocal
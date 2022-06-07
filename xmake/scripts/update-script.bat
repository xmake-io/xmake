@echo off

echo Removing old files
cd /d "%~1"
del actions core includes languages modules platforms plugins repository rules scripts templates themes /S /Q /F >nul
echo Copying from temp directory to "%~1"

if exist "%WINDIR%\System32\Robocopy.exe" (
    robocopy "%~2" "%~1" /S /IS /NFL /NDL /NJH /NJS >nul
) else (
    if exist "%WINDIR%\SysWOW64\Robocopy.exe" (
        robocopy "%~2" "%~1" /S /IS /NFL /NDL /NJH /NJS >nul
    ) else (
        xcopy "%~2" "%~1" /S /Y /Q >nul 
    )
)

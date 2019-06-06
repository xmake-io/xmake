@echo off

echo Removing old files
cd /d "%~1"
del actions core includes languages modules platforms plugins repository rules scripts templates themes /S /Q /F >nul
echo Copying from temp directory to "%~1"
xcopy "%~2" "%~1" /S /Y /Q >nul
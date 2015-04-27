@echo off
if not exist tool\msys\bin tool\7z.exe x tool\msys\bin.7z -otool\msys > nul
if not exist tool\msys\local\bin tool\7z.exe x tool\msys\local\bin.7z -otool\msys\local > nul
if not exist tool\msys\local\inc tool\7z.exe x tool\msys\local\inc.7z -otool\msys\local > nul
if not exist tool\msys\local\lib tool\7z.exe x tool\msys\local\lib.7z -otool\msys\local > nul
rem echo '%temp%' /tmp > tool\msys\etc\fstab
echo HOME='%~dp0' > tool\msys\etc\home
cmd /K tool\msys\msys.bat
exit

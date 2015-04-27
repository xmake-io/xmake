@echo off

rem compile xmake-core
echo compiling xmake-core...
cd core
cmd /K build.bat
cd ..

rem ok
echo ok!
pause

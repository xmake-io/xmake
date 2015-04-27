@echo off

rem create the xmake install directory
if %PROCESSOR_ARCHITECTURE%==x86_64 (
    set xmake_dir_install_default=C:\Program Files (x86^)\xmake
) else (
    set xmake_dir_install_default=C:\Program Files\xmake
)
echo please input the install directory
set /p xmake_dir_install=(default: %xmake_dir_install_default%): 
if "%xmake_dir_install%"=="" set xmake_dir_install=%xmake_dir_install_default%
if not exist "%xmake_dir_install%" mkdir "%xmake_dir_install%"

rem install the xmake core file
set xmake_core=core\bin\demo.pkg\bin\msvc\x86\demo.exe
set xmake_core_install=%xmake_dir_install%\xmake.exe
copy /Y "%xmake_core%" "%xmake_core_install%"

rem install the xmake directory
xcopy "xmake\" "%xmake_dir_install%"

rem compile xmake-core
echo compiling xmake-core...
cd core
cmd /K build.bat
cd ..

rem ok
echo ok!
pause

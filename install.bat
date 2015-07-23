@echo off

rem get the admin permissions  
>nul 2>&1 "%systemroot%\system32\cacls.exe" "%systemroot%\system32\config\system"  
if '%errorlevel%' neq '0' (  
    echo requesting administrative privileges...  
    goto uac_prompt  
) else ( goto got_admin )  
  
:uac_prompt  
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"  
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"  
  
    "%temp%\getadmin.vbs"  
    exit -B

:got_admin  
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )  
    pushd "%cd%"  
    cd /D "%~dp0"  

rem create the xmake install directory
if %PROCESSOR_ARCHITECTURE%==x86_64 (
    set xmake_dir_install_default=C:\Program Files (x86^)\xmake
) else (
    set xmake_dir_install_default=C:\Program Files\xmake
)
echo please input the install directory
set /p xmake_dir_install=(default: %xmake_dir_install_default%): 
if "%xmake_dir_install%"=="" set xmake_dir_install=%xmake_dir_install_default%
if exist "%xmake_dir_install%" rmdir /s /q "%xmake_dir_install%"
if not exist "%xmake_dir_install%" mkdir "%xmake_dir_install%"

rem compile xmake-core
echo compiling xmake-core...
cd core
cmd /K build.bat
cd ..

rem install the xmake core file
set xmake_core=core\bin\demo.pkg\bin\msvc\x86\demo.exe
set xmake_core_install=%xmake_dir_install%\xmake_core.exe
copy /Y "%xmake_core%" "%xmake_core_install%" > install.log

rem install the xmake directory
xcopy /S /Q /Y "xmake" "%xmake_dir_install%" >> install.log

rem make the xmake loader
set xmake_loader=%temp%\xmake_loader
echo @echo off > %xmake_loader%
echo set XMAKE_PROGRAM_DIR=%xmake_dir_install%>> %xmake_loader%
echo "%xmake_core_install%" %%* >> %xmake_loader%

rem install the xmake loader
set xmake_loader_install=%xmake_dir_install%\xmake.bat
copy /Y "%xmake_loader%" "%xmake_loader_install%" >> install.log

rem set global PATH=%xmake_dir_install%
echo %path% | findstr /i /C:"%xmake_dir_install%" >> nul && (goto set_path_ok)
tools\dtreg.exe -MachineEnvSet path="%path%;%xmake_dir_install%" >> install.log
:set_path_ok

rem ok
echo ok!
pause

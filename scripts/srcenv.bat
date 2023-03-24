@echo off
setlocal
set script_dir=%~dp0
set PATH=%script_dir%..\core\build;%cd%;%PATH%
set XMAKE_PROGRAM_DIR=%script_dir%..\xmake
start cmd /k cd %script_dir%..\
endlocal
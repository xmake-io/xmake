@REM @echo off

@set "XMAKE_EXE=%~dp0xmake.exe"
@if [%1]==[env] (
    if [%2]==[quit] (
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            if %errorlevel% neq 0 exit /B %errorlevel%
            set PROMPT=%XMAKE_PROMPT_BACKUP%
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
        )
        goto :ENDXREPO
    )
    if [%2]==[shell] (
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            if %errorlevel% neq 0 exit /B %errorlevel%
            set PROMPT=%XMAKE_PROMPT_BACKUP%
            for /f %%i in ('%XMAKE_EXE% lua private.xrepo.action.env.info prompt') do @set "PROMPT=%%i %XMAKE_PROMPT_BACKUP%"
        ) else (
            set XMAKE_PROMPT_BACKUP=%PROMPT%
            for /f %%i in ('%XMAKE_EXE% lua private.xrepo.action.env.info prompt') do @set "PROMPT=%%i %PROMPT%"
        )
        for /f %%i in ('%XMAKE_EXE% lua private.xrepo.action.env.info envfile') do @(
            set "XMAKE_ENV_BACKUP=%%i.bat"
            @"%XMAKE_EXE%" lua private.xrepo.action.env.info backup.cmd 1>"%%i.bat"
        )
        for /f %%i in ('%XMAKE_EXE% lua private.xrepo.action.env.info envfile') do @(
            @"%XMAKE_EXE%" lua private.xrepo.action.env.info script.cmd 1>"%%i.bat"
            call "%%i.bat"
        )
        goto :ENDXREPO
    )
)

@call %XMAKE_EXE% lua private.xrepo %*

:ENDXREPO

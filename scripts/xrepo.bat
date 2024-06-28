@set "XMAKE_ROOTDIR=%~dp0"
@if not defined XMAKE_PROGRAM_FILE (
    @set "XMAKE_PROGRAM_FILE=%XMAKE_ROOTDIR%xmake.exe"
)

@if [%1]==[env] (
    if [%2]==[quit] (
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            setlocal EnableDelayedExpansion
            if !errorlevel! neq 0 exit /B !errorlevel!
            endlocal
            set "PROMPT=%XMAKE_PROMPT_BACKUP%"
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
        )
        goto :ENDXREPO
    )
    if [%2]==[shell] (
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            setlocal EnableDelayedExpansion
            if !errorlevel! neq 0 exit /B !errorlevel!
            "%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info config
            if !errorlevel! neq 0 (
                exit /B !errorlevel!
            )
            @"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env.info prompt 1>nul
            if !errorlevel! neq 0 (
                echo error: xmake.lua not found^^!
                exit /B !errorlevel!
            )
            endlocal
            set "PROMPT=%XMAKE_PROMPT_BACKUP%"
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
            echo Please rerun `xrepo env shell` to enter the environment.
            exit /B 1
        ) else (
            setlocal EnableDelayedExpansion
            "%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info config
            if !errorlevel! neq 0 (
                exit /B !errorlevel!
            )
            @"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env | findstr . && (
                echo error: corrupt xmake.lua detected in the current directory^^!
                exit /B 1
            )
            @"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env.info prompt 1>nul
            if !errorlevel! neq 0 (
                echo error: xmake.lua not found^^!
                exit /B !errorlevel!
            )
            endlocal
            for /f %%i in ('@"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env.info prompt') do @(
                @set "PROMPT=%%i %PROMPT%"
            )
            @set "XMAKE_PROMPT_BACKUP=%PROMPT%"
        )
        for /f %%i in ('@"%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info envfile') do @(
            @set "XMAKE_ENV_BACKUP=%%i.bat"
            @"%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info backup.cmd 1>"%%i.bat"
        )
        for /f %%i in ('@"%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info envfile') do @(
            @"%XMAKE_PROGRAM_FILE%" lua private.xrepo.action.env.info script.cmd 1>"%%i.bat"
            call "%%i.bat"
        )
        goto :ENDXREPO
    )
    set XREPO_BIND_FLAG=
    if [%2]==[-b] if [%4]==[shell] (
        set XREPO_BIND_FLAG=1
    )
    if [%2]==[--bind] if [%4]==[shell] (
        set XREPO_BIND_FLAG=1
    )
    if defined XREPO_BIND_FLAG (
        set XREPO_BIND_FLAG=
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            setlocal EnableDelayedExpansion
            if !errorlevel! neq 0 exit /B !errorlevel!
            endlocal
            set "PROMPT=%XMAKE_PROMPT_BACKUP%"
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
            echo Please rerun `xrepo env %2 %3 shell` to enter the environment.
            exit /B 1
        ) else (
            pushd %XMAKE_ROOTDIR%
            setlocal EnableDelayedExpansion
            %XMAKE_PROGRAM_FILE% lua private.xrepo.action.env.info config %3
            if !errorlevel! neq 0 (
                popd
                exit /B !errorlevel!
            )
            @%XMAKE_PROGRAM_FILE% lua --quiet private.xrepo.action.env.info prompt %3 1>nul
            if !errorlevel! neq 0 (
                popd
                echo error: environment not found^^!
                exit /B !errorlevel!
            )
            endlocal
            for /f %%i in ('@%XMAKE_PROGRAM_FILE% lua --quiet private.xrepo.action.env.info prompt %3') do @(
                @set "PROMPT=%%i %PROMPT%"
            )
            @set "XMAKE_PROMPT_BACKUP=%PROMPT%"
        )
        for /f %%i in ('@%XMAKE_PROGRAM_FILE% lua private.xrepo.action.env.info envfile %3') do @(
            @set "XMAKE_ENV_BACKUP=%%i.bat"
            @"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env.info backup.cmd %3 1>"%%i.bat"
        )
        for /f %%i in ('@%XMAKE_PROGRAM_FILE% lua private.xrepo.action.env.info envfile %3') do @(
            @"%XMAKE_PROGRAM_FILE%" lua --quiet private.xrepo.action.env.info script.cmd %3 1>"%%i.bat"
            call "%%i.bat"
        )
        popd
        goto :ENDXREPO
    )
)

@call "%XMAKE_PROGRAM_FILE%" lua private.xrepo %*

:ENDXREPO

@set "XMAKE_EXE=xmake"

@if [%1]==[env] (
    if [%2]==[quit] (
        if defined XMAKE_PROMPT_BACKUP (
            call %XMAKE_ENV_BACKUP%
            setlocal EnableDelayedExpansion
            if !errorlevel! neq 0 exit /B !errorlevel!
            endlocal
            set PROMPT=%XMAKE_PROMPT_BACKUP%
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
            %XMAKE_EXE% lua private.xrepo.action.env.info config
            if !errorlevel! neq 0 (
                exit /B !errorlevel!
            )
            @%XMAKE_EXE% lua --quiet private.xrepo.action.env.info prompt 1>nul
            if !errorlevel! neq 0 (
                echo error: xmake.lua not found^^!
                exit /B !errorlevel!
            )
            endlocal
            set PROMPT=%XMAKE_PROMPT_BACKUP%
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
            echo Please rerun `xrepo env shell` to enter the environment.
            exit /B 1
        ) else (
            setlocal EnableDelayedExpansion
            %XMAKE_EXE% lua private.xrepo.action.env.info config
            if !errorlevel! neq 0 (
                exit /B !errorlevel!
            )
            @%XMAKE_EXE% lua --quiet private.xrepo.action.env.info prompt 1>nul
            if !errorlevel! neq 0 (
                echo error: xmake.lua not found^^!
                exit /B !errorlevel!
            )
            endlocal
            for /f %%i in ('@%XMAKE_EXE% lua --quiet private.xrepo.action.env.info prompt') do @(
                @set "PROMPT=%%i %PROMPT%"
            )
            @set XMAKE_PROMPT_BACKUP=%PROMPT%
        )
        for /f %%i in ('@%XMAKE_EXE% lua private.xrepo.action.env.info envfile') do @(
            @set "XMAKE_ENV_BACKUP=%%i.bat"
            @"%XMAKE_EXE%" lua private.xrepo.action.env.info backup.cmd 1>"%%i.bat"
        )
        for /f %%i in ('@%XMAKE_EXE% lua private.xrepo.action.env.info envfile') do @(
            @"%XMAKE_EXE%" lua private.xrepo.action.env.info script.cmd 1>"%%i.bat"
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
            set PROMPT=%XMAKE_PROMPT_BACKUP%
            set XMAKE_ENV_BACKUP=
            set XMAKE_PROMPT_BACKUP=
            echo Please rerun `xrepo env shell` to enter the environment.
            exit /B 1
        ) else (
            setlocal EnableDelayedExpansion
            %XMAKE_EXE% lua private.xrepo.action.env.info config %3
            if !errorlevel! neq 0 (
                exit /B !errorlevel!
            )
            @%XMAKE_EXE% lua --quiet private.xrepo.action.env.info prompt %3 1>nul
            if !errorlevel! neq 0 (
                echo error: environment not found^^!
                exit /B !errorlevel!
            )
            endlocal
            for /f %%i in ('@%XMAKE_EXE% lua --quiet private.xrepo.action.env.info prompt %3') do @(
                @set "PROMPT=%%i %PROMPT%"
            )
            @set XMAKE_PROMPT_BACKUP=%PROMPT%
        )
        for /f %%i in ('@%XMAKE_EXE% lua private.xrepo.action.env.info envfile %3') do @(
            @set "XMAKE_ENV_BACKUP=%%i.bat"
            @"%XMAKE_EXE%" lua --quiet private.xrepo.action.env.info backup.cmd %3 1>"%%i.bat"
        )
        for /f %%i in ('@%XMAKE_EXE% lua private.xrepo.action.env.info envfile %3') do @(
            @"%XMAKE_EXE%" lua --quiet private.xrepo.action.env.info script.cmd %3 1>"%%i.bat"
            call "%%i.bat"
        )
        goto :ENDXREPO
    )
)

@call %XMAKE_EXE% lua private.xrepo %*

:ENDXREPO

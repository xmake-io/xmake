$BASEDIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (Test-Path "$BASEDIR\..\share\xmake\xmake.exe") {
    & "$BASEDIR\..\share\xmake\xmake.exe" @args
}
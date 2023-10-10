$xmake_root = (Split-Path $PSScriptRoot -Parent)
$env:PATH = "$xmake_root\core\build;$pwd;$env:PATH"
$env:XMAKE_PROGRAM_FILE = "$xmake_root\core\build\xmake.exe"
$env:XMAKE_PROGRAM_DIR = "$xmake_root\xmake"
Set-Location "$xmake_root"
Start-Process powershell
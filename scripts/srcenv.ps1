$script_dir = Split-Path $MyInvocation.MyCommand.Path
$env:PATH = "$script_dir\..\core\build;$pwd;$env:PATH" 
$env:XMAKE_PROGRAM_DIR = "$script_dir\..\xmake"
Set-Location "$script_dir\.."
Start-Process powershell
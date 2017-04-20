# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

$ver='v2.1.3'
Invoke-Webrequest "https://github.com/tboox/xmake/releases/download/$ver/xmake-$ver.exe" -OutFile "$pid-xmake-installer.exe"
Start-Process -FilePath "$pid-xmake-installer.exe" -ArgumentList '/S /D=C:\xmake' -Wait
Remove-Item "$pid-xmake-installer.exe"
$env:Path+=";C:\xmake"
[Environment]::SetEnvironmentVariable("Path",$env:Path,[System.EnvironmentVariableTarget]::User)
xmake --version
